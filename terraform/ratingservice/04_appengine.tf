/**
 * Copyright 2021 Google LLC
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

# provision App Engine service
locals {
  max_connections = 10
  service_port    = 8080
}

data "external" "app_engine_state" {
  program = ["${path.module}/setup_app_engine.sh", var.gcp_project_id]
}

resource "google_app_engine_application" "app" {
  project     =  var.gcp_project_id
  count       = data.external.app_engine_state.result.application_exist == "false" ? 1 : 0
  location_id = var.gcp_region_name

  depends_on = [google_project_service.gae, google_project_service.cloudbuild]
}

resource "google_app_engine_standard_app_version" "default" {
  count      = data.external.app_engine_state.result.default_svc_exist == "false" ? 1 : 0
  project    =  var.gcp_project_id
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
  depends_on      = [google_project_service.gae, google_project_service.cloudbuild, google_storage_bucket_object.requirements, google_storage_bucket_object.default_main. google_storage_bucket_object.main]
}

resource "google_app_engine_standard_app_version" "ratingservice" {
  project    =  var.gcp_project_id
  service    = var.service_name
  version_id = var.service_version
  runtime    = "python38"

  entrypoint {
    shell = "uwsgi --http-socket :${local.service_port} --wsgi-file main.py --callable app --master --processes 1 --threads ${local.max_connections}"
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
    PORT               = local.service_port
  }

  inbound_services = ["INBOUND_SERVICE_WARMUP"]

  automatic_scaling {
    standard_scheduler_settings {
      min_instances = 1
    }
    max_concurrent_requests = 9
    min_idle_instances      = 1
    max_idle_instances      = 1
  }

  delete_service_on_destroy = true
  depends_on                = [google_app_engine_standard_app_version.default]
}
