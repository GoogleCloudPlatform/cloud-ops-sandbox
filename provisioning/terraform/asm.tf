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
      ./scripts/install_asm.sh --project ${self.triggers.project_id} \
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
