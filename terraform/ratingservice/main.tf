/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


terraform {
  # The module has 0.12 syntax and is not compatible with any versions below 0.12.
  required_version = ">= 0.12"
}

provider "google" {
  version = "~> 3.0"

  project = var.gcp_project_id
  region  = var.gcp_region_name
}

provider "random" {
  version = "~> 2.0"
}

resource "google_project_service" "gae" {
  service                    = "appengine.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "cloudscheduler" {
  service                    = "cloudscheduler.googleapis.com"
  disable_dependent_services = true
}

resource "random_string" "suffix" {
  upper   = false
  special = false
  length  = 4
}

# provision CloudSQL
resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "google_sql_database_instance" "rating_service" {
  name                = "ratingservice-sql-instance-${random_string.suffix.result}"
  database_version    = "POSTGRES_12"
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_user" "default" {
  name     = "postgres"
  password = random_password.db_password.result
  instance = google_sql_database_instance.rating_service.name
}

resource "google_sql_database" "rating_service" {
  name     = "rating-db"
  instance = google_sql_database_instance.rating_service.name

  provisioner "local-exec" {
    command = "${path.module}/configure_rating_db.sh ${var.gcp_project_id}"
    environment = {
      DB_HOST     = google_sql_database_instance.rating_service.connection_name
      DB_NAME     = google_sql_database.rating_service.name
      DB_USERNAME = google_sql_user.default.name
      DB_PASSWORD = google_sql_user.default.password
    }
  }
}

# provision App Engine service
locals {
  max_connections = 10
  service_name    = "ratingservice"
  service_version = "prod"
  source_path     = "${path.root}/../src/ratingservice"
}

resource "google_storage_bucket" "it" {
  name                        = "${var.gcp_project_id}-ratingservice-${random_string.suffix.result}"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "requirements" {
  name   = "requirements.txt"
  bucket = google_storage_bucket.it.name
  source = "${local.source_path}/requirements.txt"
}

resource "google_storage_bucket_object" "main" {
  name   = "ratingservice/main.py"
  bucket = google_storage_bucket.it.name
  source = "${local.source_path}/main.py"
}

resource "google_storage_bucket_object" "default_main" {
  name   = "default/main.py"
  bucket = google_storage_bucket.it.name
  source = "${local.source_path}/pong.py"
}

data "external" "app_engine_state" {
  program = ["${path.module}/setup_app_engine.sh", var.gcp_project_id]
}

resource "google_app_engine_application" "app" {
  count       = data.external.app_engine_state.result.application_exist == "false" ? 1 : 0
  location_id = var.gcp_region_name

  depends_on = [google_project_service.gae]
}

resource "google_app_engine_standard_app_version" "default" {
  count      = data.external.app_engine_state.result.default_svc_exist == "false" ? 1 : 0
  service    = "default"
  version_id = "v1"
  runtime    = "python38"

  entrypoint {
    shell = "uwsgi --http-socket :8080 --wsgi-file main.py --callable app --master --processes 1 --threads 1"
  }

  deployment {
    files {
      name       = "requirements.txt"
      source_url = "https://storage.googleapis.com/${google_storage_bucket.it.name}/${google_storage_bucket_object.requirements.name}"
    }
    files {
      name       = "main.py"
      source_url = "https://storage.googleapis.com/${google_storage_bucket.it.name}/${google_storage_bucket_object.default_main.name}"
    }
  }

  noop_on_destroy = true
  depends_on      = [google_project_service.gae]
}

resource "google_app_engine_standard_app_version" "ratingservice" {
  service    = local.service_name
  version_id = local.service_version
  runtime    = "python38"

  entrypoint {
    shell = "uwsgi --http-socket :8080 --wsgi-file main.py --callable app --master --processes 1 --threads ${local.max_connections}"
  }

  deployment {
    files {
      name       = "requirements.txt"
      source_url = "https://storage.googleapis.com/${google_storage_bucket.it.name}/${google_storage_bucket_object.requirements.name}"
    }
    files {
      name       = "main.py"
      source_url = "https://storage.googleapis.com/${google_storage_bucket.it.name}/${google_storage_bucket_object.main.name}"
    }
  }

  env_variables = {
    DB_HOST            = google_sql_database_instance.rating_service.connection_name
    DB_NAME            = google_sql_database.rating_service.name
    DB_USERNAME        = google_sql_user.default.name
    DB_PASSWORD        = google_sql_user.default.password
    MAX_DB_CONNECTIONS = local.max_connections
  }

  basic_scaling {
    max_instances = 10
    idle_timeout  = "600s"
  }

  delete_service_on_destroy = true
  depends_on                = [google_app_engine_standard_app_version.default]
}

resource "google_cloud_scheduler_job" "recollect_job" {
  name             = "ratingservice-recollect-job"
  schedule         = "*/2 * * * *" # each two minutes
  description      = "recollect recently posted new votes"
  time_zone        = "Europe/London"
  attempt_deadline = "340s"

  retry_config {
    min_backoff_duration = "1s"
    max_retry_duration   = "10s"
    max_doublings        = 2
    retry_count          = 3
  }

  app_engine_http_target {
    http_method = "PUT"

    app_engine_routing {
      service = local.service_name
      version = local.service_version
    }

    relative_uri = "/recollect"
  }

  depends_on = [google_project_service.cloudscheduler, google_app_engine_standard_app_version.ratingservice]
}
