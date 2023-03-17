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

# Apply YAML kubernetes-manifest configurations
# NOTE: when re-applying the previous resources might not be disposed

locals {
  load_balancer_service_name      = var.enable_asm ? "asm-ingressgateway" : "frontend-external"
  load_balancer_service_namespace = var.enable_asm ? "asm-ingress" : "default"
}

resource "null_resource" "online_boutique_kustomization" {
  triggers = {
    kustomize_path = sha256(var.filepath_manifest)
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "kubectl apply -k ${var.filepath_manifest} -n default"
  }

  depends_on = [
    module.gcloud,
    null_resource.online_boutique_gateways_kustomization,
  ]
}

# Wait condition for all resources to be ready before finishing
resource "null_resource" "wait_pods_are_ready" {
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "kubectl wait --for=condition=ready pods --all -n default --timeout=5m 2>/dev/null"
  }

  depends_on = [
    null_resource.online_boutique_kustomization
  ]
}

resource "null_resource" "wait_service_conditions" {
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "while [[ -z $ip ]]; do ip=$(kubectl get svc ${local.load_balancer_service_name} -n ${local.load_balancer_service_namespace} --output='go-template={{range .status.loadBalancer.ingress}}{{.ip}}{{end}}'); sleep 1; done 2>/dev/null"
  }

  depends_on = [
    null_resource.online_boutique_kustomization
  ]
}
