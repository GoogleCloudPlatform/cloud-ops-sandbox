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
  location_label  = length(split("-", var.gke_cluster_location)) == 2 ? "--region" : (length(split("-", var.gke_cluster_location)) == 3 ? "--zone" : "--location")
  resource_labels = var.enable_asm ? { "mesh_id" = "proj-${data.google_project.info.number}" } : {}
}

data "google_project" "info" {
  project_id = var.gcp_project_id
}

resource "google_container_cluster" "sandbox" {
  name     = var.gke_cluster_name
  location = var.gke_cluster_location

  release_channel {
    channel = "STABLE"
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  resource_labels = local.resource_labels

  description = "Provisioned for Cloud Ops Sandbox version ${var.sandbox_version}"

  # Enables Workload Identity
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Configures default node pool
  node_pool {
    initial_node_count = var.gke_node_pool.initial_node_count

    node_config {
      machine_type = var.gke_node_pool.machine_type
      labels       = var.gke_node_pool.labels
      oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

      # Enables Workload Identity
      workload_metadata_config {
        mode = "GKE_METADATA"
      }
    }

    dynamic "autoscaling" {
      for_each = var.gke_node_pool.autoscaling != null ? [var.gke_node_pool.autoscaling] : []
      content {
        min_node_count = autoscaling.value.min_node_count
        max_node_count = autoscaling.value.max_node_count
      }
    }
  }
}

module "gcloud" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.1.0"

  platform              = "linux"
  additional_components = ["kubectl", "beta"]

  create_cmd_entrypoint = "gcloud"
  # Module does not support explicit dependency
  # Use 'local.cluster_name' to enforce implicit dependency because 'depends_on' is not available for this module
  create_cmd_body = "container clusters get-credentials ${resource.google_container_cluster.sandbox.name} ${local.location_label}=${resource.google_container_cluster.sandbox.location} --project=${var.gcp_project_id}"
}

resource "null_resource" "install_asm" {
  count = var.enable_asm ? 1 : 0

  triggers = {
    project_id       = var.gcp_project_id
    cluster_name     = google_container_cluster.sandbox.name
    cluster_location = google_container_cluster.sandbox.location
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = <<-EOT
      ${path.module}/scripts/install_asm.sh --project ${self.triggers.project_id} \
        --channel ${var.asm_channel} \
        --cluster_name ${self.triggers.cluster_name} \
        --cluster_location ${self.triggers.cluster_location}
EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      gcloud container fleet memberships unregister ${self.triggers.cluster_name} \
        --gke-cluster '${self.triggers.cluster_location}/${self.triggers.cluster_name}' \
        --project=${self.triggers.project_id}
EOT
  }

  depends_on = [
    resource.google_container_cluster.sandbox,
    module.gcloud,
  ]
}
