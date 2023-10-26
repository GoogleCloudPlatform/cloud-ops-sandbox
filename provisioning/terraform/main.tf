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


# ------------------------------------------
# Infra
module "k8s_cluster" {
  source               = "./k8s_cluster"
  asm_channel          = var.asm_channel
  enable_asm           = var.enable_asm
  gcp_project_id       = module.enable_google_apis.project_id
  gke_cluster_location = var.gke_cluster_location
  gke_cluster_name     = var.gke_cluster_name
  gke_node_pool        = var.gke_node_pool
  sandbox_version      = var.sandbox_version
}

# ------------------------------------------
# Demo application
module "online_boutique" {
  source            = "./microservice_demo"
  depends_on        = [module.k8s_cluster]
  enable_asm        = var.enable_asm
  manifest_filepath = var.manifest_filepath
  gcp_project_id    = module.enable_google_apis.project_id
}

# # ------------------------------------------
# # Cloud Ops configuration
module "cloud_ops" {
  source     = "./cloud-ops"
  depends_on = [module.online_boutique]
  # hardcoded additional variables for configurations
  # TODO: change to more dynamic solution to support multiple demo apps
  additional_configuration_vars = { public_hostname = module.online_boutique.frontend_ip_address }

  configuration_filepath = var.configuration_filepath
  enable_asm             = var.enable_asm
  gcp_project_id         = module.enable_google_apis.project_id
  gke_cluster_name       = var.gke_cluster_name
  # re-use prefix to customize resources within the same project
  name_suffix = length(var.state_prefix) > 0 ? var.state_prefix : ""
}
