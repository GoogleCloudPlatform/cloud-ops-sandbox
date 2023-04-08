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

locals {
  service_name   = var.enable_asm ? "istio-gateway" : "frontend-external"
  namespace_name = "default"
}

# Deploy kustomized manifests
# NOTE: when re-applying the previous resources might not be disposed
resource "null_resource" "online_boutique_kustomization" {
  triggers = {
    kustomize_path = sha256(var.filepath_manifest)
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "kubectl apply -k ${var.filepath_manifest} -n ${local.namespace_name}"
  }

  depends_on = [
    module.gcloud,
    null_resource.install_asm
  ]
}

# Wait condition for all resources to be ready before finishing
resource "null_resource" "wait_pods_are_ready" {
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "kubectl wait --for=condition=ready pods --all -n ${local.namespace_name} --timeout=5m 2>/dev/null"
  }

  depends_on = [
    null_resource.online_boutique_kustomization
  ]
}

# # TODO: refactor waiting and retrieving external IP
resource "null_resource" "wait_service_conditions" {
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = <<EOF
while [[ -z $ip ]]; do \
    ip=$(kubectl get svc ${local.service_name} \
    -n ${local.namespace_name} \
    --output='go-template={{range .status.loadBalancer.ingress}}{{.ip}}{{end}}'); \
    sleep 1; \
done 2>/dev/null
EOF
  }

  depends_on = [
    null_resource.online_boutique_kustomization
  ]
}

data "kubernetes_service" "frontend_external_service" {
  metadata {
    name      = local.service_name
    namespace = local.namespace_name
  }
  # Kubernetes data sources do not support implicit dependencies
  # https://github.com/hashicorp/terraform-provider-kubernetes/issues/1867
  depends_on = [
    null_resource.wait_service_conditions
  ]
}
