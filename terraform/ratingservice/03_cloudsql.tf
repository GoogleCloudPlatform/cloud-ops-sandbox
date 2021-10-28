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

resource "random_string" "suffix_len_4" {
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
  name                = "ratingservice-sql-instance-${random_string.suffix_len_4.result}"
  database_version    = "POSTGRES_12"
  deletion_protection = false
  region              = var.gcp_region_name
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