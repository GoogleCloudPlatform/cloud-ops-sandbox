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
    command     = <<EOF
./scripts/install_asm.sh --project ${var.gcp_project_id} \
    --channel ${var.asm_channel} \
    --cluster_name ${resource.google_container_cluster.sandbox.name} \
    --cluster_location ${resource.google_container_cluster.sandbox.location}
EOF
  }
  depends_on = [
    resource.google_container_cluster.sandbox,
    module.gcloud,
  ]
}

# resource "kubernetes_namespace" "istio_gateway" {
#   count = var.enable_asm ? 1 : 0
#   metadata {
#     name = "istio-gateway"
#     labels = {
#       "istio.io/rev" = "asm-managed-${var.asm_channel}"
#     }
#   }
# }

# resource "kubernetes_deployment" "istio_ingressgateway" {
#   count = var.enable_asm ? 1 : 0
#   metadata {
#     name      = "istio-ingressgateway"
#     namespace = kubernetes_namespace.istio_gateway[0].metadata[0].name
#   }
#   spec {
#     selector {
#       match_labels = {
#         app   = "istio-ingressgateway"
#         istio = "ingressgateway"
#       }
#     }

#     template {
#       metadata {
#         # This is required to tell Anthos Service Mesh to inject the gateway
#         # with the required configuration.
#         annotations = {
#           "inject.istio.io/templates" = "gateway"
#         }
#         labels = {
#           app   = "istio-ingressgateway"
#           istio = "ingressgateway"
#         }
#       }
#       spec {
#         container {
#           image = "auto" # The image will automatically update each time the pod starts.
#           name  = "istio-proxy"
#           resources {
#             limits = {
#               cpu    = "2000m"
#               memory = "1024Mi"
#             }
#             requests = {
#               cpu    = "100m"
#               memory = "128Mi"
#             }
#           }
#         }
#       }
#     }
#   }
#   depends_on = [
#     null_resource.install_asm
#   ]
# }

# resource "kubernetes_service" "istio_ingressgateway" {
#   count = var.enable_asm ? 1 : 0
#   metadata {
#     name      = "istio-ingressgateway"
#     namespace = kubernetes_namespace.istio_gateway[0].metadata[0].name
#     labels = {
#       app   = "istio-ingressgateway"
#       istio = "ingressgateway"
#     }
#   }
#   spec {
#     type = "LoadBalancer"
#     selector = {
#       app   = "istio-ingressgateway"
#       istio = "ingressgateway"
#     }
#     port {
#       name        = "status-port"
#       port        = 15021
#       protocol    = "TCP"
#       target_port = 15021
#     }
#     port {
#       name = "http2"
#       port = 80

#     }
#     port {
#       name = "https"
#       port = 443
#     }
#   }
#   depends_on = [
#     null_resource.install_asm
#   ]
# }

# resource "kubernetes_role" "example" {
#   count = var.enable_asm ? 1 : 0
#   metadata {
#     name      = "istio-ingressgateway"
#     namespace = kubernetes_namespace.istio_gateway[0].metadata[0].name
#   }
#   rule {
#     api_groups = [""]
#     resources  = ["secrets"]
#     verbs      = ["get", "watch", "list"]
#   }
# }

# resource "kubernetes_role_binding" "example" {
#   count = var.enable_asm ? 1 : 0
#   metadata {
#     name      = "istio-ingressgateway"
#     namespace = kubernetes_namespace.istio_gateway[0].metadata[0].name
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "Role"
#     name      = "istio-ingressgateway"
#   }
#   subject {
#     kind = "ServiceAccount"
#     name = "default"
#   }
# }
