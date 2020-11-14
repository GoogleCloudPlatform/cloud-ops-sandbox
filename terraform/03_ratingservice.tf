# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "random_password" "db_password" {
  count   = var.enable_rating_service ? 1 : 0
  length  = 16
  special = false
}

resource "google_sql_database_instance" "rating_service" {
  count               = var.enable_rating_service ? 1 : 0
  project             = data.google_project.project.project_id
  name                = "rating-service-sql-instance"
  database_version    = "POSTGRES_12"
  region              = var.rating_service_region_name
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "rating_service" {
  count    = var.enable_rating_service ? 1 : 0
  project  = data.google_project.project.project_id
  name     = "rating-db"
  instance = google_sql_database_instance.rating_service[0].name
}

resource "google_sql_user" "default" {
  count    = var.enable_rating_service ? 1 : 0
  project  = data.google_project.project.project_id
  name     = "postgres"
  password = random_password.db_password[0].result
  instance = google_sql_database_instance.rating_service[0].name
}

#
# create schema and populate Postgres DB
#
resource "null_resource" "rating_db_configuration" {
  count = var.enable_rating_service ? 1 : 0
  provisioner "local-exec" {
    command = "./ratingservice/configure_rating_db.sh"
    environment = {
      INSTANCE_NAME = google_sql_database_instance.rating_service[0].name
      DBHOST        = google_sql_database_instance.rating_service[0].public_ip_address
      DBNAME        = google_sql_database.rating_service[0].name
      DBUSER        = google_sql_user.default[0].name
      DBPWD         = google_sql_user.default[0].password
    }
  }

  depends_on = [google_project_service.sqladmin, google_sql_database.rating_service[0], google_sql_user.default[0]]
}

#
# deploy rating service to App Engine
#
resource "null_resource" "rating_service_deployment1" {
  count = var.enable_rating_service ? 1 : 0
  provisioner "local-exec" {
    command = "./ratingservice/deploy_rating_service.sh"
    environment = {
      REGION  = var.rating_service_region_name
      SERVICE = "default"
      VERSION = "prod"
      # escape slashes to allow substituting the value with 'sed'
      DB_HOST     = "\\/cloudsql\\/${google_sql_database_instance.rating_service[0].connection_name}"
      DB_NAME     = google_sql_database.rating_service[0].name
      DB_USERNAME = google_sql_user.default[0].name
      DB_PASSWORD = google_sql_user.default[0].password
    }
  }
  provisioner "local-exec" {
    when    = destroy
    command = "./ratingservice/deploy_rating_service.sh"
    environment = {
      DELETE = 1
    }
  }

  depends_on = [null_resource.rating_db_configuration[0]]
}

resource "google_cloud_scheduler_job" "recollect_job" {
  count            = var.enable_rating_service ? 1 : 0
  name             = "rating-service-recollect-job"
  project          = data.google_project.project.project_id
  region           = var.rating_service_region_name
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

    # there is only one service and one version. parameters below are just for the reference
    # app_engine_routing {
    #   service = "default"
    #   version = "prod"
    # }

    relative_uri = "/recollect"
  }

  depends_on = [google_project_service.cloudscheduler]
}
