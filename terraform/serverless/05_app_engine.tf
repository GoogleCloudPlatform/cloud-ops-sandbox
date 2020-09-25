# Copyright 2019 Google LLC
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

resource "google_app_engine_standard_app_version" "ratingservice_v1" {
  version_id = "v1"
  service    = "ratingservice"
  runtime    = "python38"

  entrypoint {
    shell = "uwsgi --http-socket :8080 --wsgi-file main.py --callable app --master --processes 1 --threads 2"
  }

  deployment {
    zip {
      source_url = "https://storage.googleapis.com/${var.bucket_name}/ratingservice_code:${var.code_tag}.zip"
    }
  }

  env_variables = {
    CLOUD_SQL_DATABASE_NAME = google_sql_database.database.name
    CLOUD_SQL_USERNAME = google_sql_user.default.name
    CLOUD_SQL_PASSWORD = google_sql_user.default.password
    CLOUD_SQL_CONNECTION_NAME = google_sql_database_instance.master.connection_name
  }

  basic_scaling {
    # maximum instance to create for this version when requests come
    max_instances = 5
  }

  delete_service_on_destroy = true
}

variable "code_tag" {
  type        = string
  description = "The release tag of the source code. Case-sensitive."
  default     = "latest"
}