# Copyright 2023 Google LLC
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

data "external" "frontend_service_external_ip" {
  depends_on = [resource.null_resource.wait_kustomize_conditions]
  program    = ["bash", "./external_ip.sh"]
}

module "monitoring" {
  source               = "./monitoring"
  gcp_project_id       = var.gcp_project_id
  frontend_external_ip = data.external.frontend_service_external_ip.result.ip
  gke_cluster_name     = var.gke_cluster_name
  manifest_namespace   = var.manifest_namespace
}
