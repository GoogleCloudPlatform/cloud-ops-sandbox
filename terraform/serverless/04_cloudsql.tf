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

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "random_id" "db_password" {
  byte_length = 4
}

resource "google_sql_database_instance" "master" {
  name             = "master-instance-${random_id.db_name_suffix.hex}"
  database_version = "POSTGRES_12"
  region           = "us-west2"

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "database" {
  name     = "rating-databse"
  instance = google_sql_database_instance.master.name
}

resource "google_sql_user" "default" {
  name     = "postgres"
  password = random_id.db_password.hex
  instance = google_sql_database_instance.master.name
}