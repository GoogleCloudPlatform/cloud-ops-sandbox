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
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "./scripts/install_asm.sh --project ${var.gcp_project_id} --cluster_name ${resource.google_container_cluster.sandbox.name} --cluster_location ${resource.google_container_cluster.sandbox.location}"
  }
  depends_on = [
    resource.google_container_cluster.sandbox,
    module.gcloud,
  ]
}

resource "null_resource" "asm_ingress_kustomization" {
  count = var.enable_asm ? 1 : 0
  triggers = {
    kustomize_path = sha256(var.filepath_manifest)
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "kubectl apply -k \"../kustomize/asm/\""
  }

  depends_on = [
    null_resource.install_asm
  ]
}

resource "null_resource" "online_boutique_gateways_kustomization" {
  count = var.enable_asm ? 1 : 0
  triggers = {
    kustomize_path = sha256(var.filepath_manifest)
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "kubectl apply -k \"../kustomize/online-boutique/gateway-ingress/\" -n default"
  }

  depends_on = [
    null_resource.asm_ingress_kustomization
  ]
}
