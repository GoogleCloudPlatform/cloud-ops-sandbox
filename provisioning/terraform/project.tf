# Copyright 2023 Google LLC
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

# Enable Google Cloud APIs
locals {
  base_apis = [
    "clouderrorreporting.googleapis.com",
    "cloudprofiler.googleapis.com",
    "container.googleapis.com", /* compute.googleapis.com is provisioned as a dependency */
  ]
  mesh_apis = [
    "mesh.googleapis.com",
    #    "meshtelemetry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ]
}

# Enable Google Cloud APIs
module "enable_google_apis" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.1.0"

  project_id                  = var.gcp_project_id
  disable_services_on_destroy = false

  activate_apis           = concat(local.base_apis, var.enable_asm ? local.mesh_apis : [])
}
