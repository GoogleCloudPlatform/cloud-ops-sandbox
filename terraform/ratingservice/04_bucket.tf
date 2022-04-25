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

locals {
  source_path = "${path.root}/../src/ratingservice"
}

resource "google_storage_bucket" "it" {
  # max name length is 63 char = 30 chars for project id + '-ratingservice-' + 4 char suffix
  name                        = "${var.gcp_project_id}-ratingservice-${random_string.suffix_len_4.result}"
  uniform_bucket_level_access = true
  project                     = var.gcp_project_id
  count = "${var.skip_ratingservice ? 0 : 1}"
}

resource "google_storage_bucket_object" "requirements" {
  name   = "requirements.txt"
  bucket = google_storage_bucket.it.name
  source = "${local.source_path}/requirements.txt"
  count = "${var.skip_ratingservice ? 0 : 1}"
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