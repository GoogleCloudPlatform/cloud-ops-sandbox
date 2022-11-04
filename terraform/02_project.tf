# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


locals {
  sandbox_version = jsondecode(data.local_file.versions.content).version

  # monitoring, tracing and logging APIs are enabled by default
  gcp_services = toset(["compute", "clouderrorreporting"])
}

data "local_file" "versions" {
  filename = "${path.module}/../versions.json"
}

resource "google_compute_project_metadata_item" "sandbox_metadata" {
  key        = "sandbox-metadata"
  value      = "{\"sandbox-version\":\"${local.sandbox_version}\",\"project-id\":\"${var.project_id}\",\"app-id\":\"${one(regex(".*/([[:alnum:]-]+)/?", var.cfg_file_location))}\"}"
  depends_on = [google_project_service.services]
}

resource "google_project_service" "services" {
  for_each                   = local.gcp_services
  service                    = "${each.value}.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}
