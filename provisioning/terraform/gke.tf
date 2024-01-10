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

locals {
  zones           = length(split("-", var.cluster_location)) == 3 ? [var.cluster_location] : []
  region          = length(split("-", var.cluster_location)) == 2 ? var.cluster_location : null
  resource_labels = var.enable_asm ? { "mesh_id" = "proj-${data.google_project.info.number}" } : {}
}

# look at https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest
module "gke" {
  source = "terraform-google-modules/kubernetes-engine/google"

  project_id                 = var.project_id
  name                       = var.cluster_name
  description                = "Provisioned for Cloud Ops Sandbox version ${file("../version.txt")}"
  region                     = local.region
  regional                   = (local.region != null)
  zones                      = local.zones
  cluster_resource_labels    = local.resource_labels
  network                    = var.cluster_network
  subnetwork                 = var.cluster_subnetwork
  ip_range_pods              = ""
  ip_range_services          = ""
  http_load_balancing        = true
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  create_service_account     = false
  deletion_protection        = false

  gateway_api_channel = "CHANNEL_STANDARD"
  release_channel     = "STABLE"
  identity_namespace  = "enabled"

  node_pools = [
    {
      name               = "default-node-pool"
      initial_node_count = var.node_pool_config.initial_node_count
      machine_type       = var.node_pool_config.machine_type
      min_count          = var.node_pool_config.min_count
      max_count          = var.node_pool_config.max_count

    },
  ]

  node_pools_oauth_scopes = {
    all = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = var.node_pool_config.labels
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }

  depends_on = [module.google_apis]
}
