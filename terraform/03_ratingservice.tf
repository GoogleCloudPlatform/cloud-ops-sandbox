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
  length = 16
  special = false
}

resource "google_sql_database_instance" "ratings" {
  project             = data.google_project.project.project_id
  name                = "ratings-sql-instance"
  database_version    = "POSTGRES_12"
  region              = var.rating_service_region_name
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "ratings" {
  project  = data.google_project.project.project_id
  name     = "ratings-db"
  instance = google_sql_database_instance.ratings.name
}

resource "google_sql_user" "default" {
  project  = data.google_project.project.project_id
  name     = "postgres"
  password = random_password.db_password.result
  instance = google_sql_database_instance.ratings.name
}

#
# create schema and populate Postgres DB
#
resource "null_resource" "rating_db_configuration" {
  provisioner "local-exec" {
    command = "./ratingservice/configure_ratings_db.sh"
    environment = {
      INSTANCE_NAME=google_sql_database_instance.ratings.name
      DBHOST=google_sql_database_instance.ratings.public_ip_address
      DBNAME=google_sql_database.ratings.name
      DBUSER=google_sql_user.default.name
      DBPWD=google_sql_user.default.password
    }
  }

  depends_on = [google_sql_database.ratings, google_sql_user.default]
}

#
# deploy rating service to GAES
#
resource "null_resource" "rating_service_deployment" {
  provisioner "local-exec" {
    command = "./ratingservice/deploy_rating_service.sh"
    environment = {
      REGION=var.rating_service_region_name
      VERSION="prod"
      DBHOST=google_sql_database_instance.ratings.public_ip_address
      DBNAME=google_sql_database.ratings.name
      DBUSER=google_sql_user.default.name
      DBPWD=google_sql_user.default.password
    }
  }
  provisioner "local-exec" {
    when    = destroy
  }

  depends_on = [null_resource.rating_db_configuration]
}

#
# deploy rating service to GAES
#
resource "google_cloud_scheduler_job" "rating_service_job" {
  name             = "process-new-votes"
  schedule         = "*/2 * * * *"
  description      = "trigger rating service to update ratings to include new posted votes"
  time_zone        = "Europe/London"
  attempt_deadline = "320s"

  retry_config {
    min_backoff_duration = "1s"
    max_retry_duration = "10s"
    max_doublings = 2
    retry_count = 3
  }

  app_engine_http_target {
    http_method = "PATCH"
    relative_uri = "/ratings"
  }

  depends_on = [null_resource.rating_service_deployment]
}