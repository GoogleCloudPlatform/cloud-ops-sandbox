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

resource "google_gke_hub_membership" "membership" {
  count    = var.enable_asm == true ? 1 : 0
  provider = google-beta

  membership_id = "membership-${var.gke_cluster_name}"
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.sandbox.id}"
    }
  }
  depends_on = [module.enable_google_apis]
}

resource "google_gke_hub_feature" "feature" {
  count    = var.enable_asm == true ? 1 : 0
  provider = google-beta

  name     = "servicemesh"
  location = "global"

  depends_on = [module.enable_google_apis]
}

resource "google_gke_hub_feature_membership" "feature_member" {
  count    = var.enable_asm == true ? 1 : 0
  provider = google-beta

  location   = "global"
  feature    = google_gke_hub_feature.feature[0].name
  membership = google_gke_hub_membership.membership[0].membership_id
  mesh {
    management = "MANAGEMENT_AUTOMATIC"
  }
}

resource "null_resource" "mark_manifest_namespace_for_istio_injection" {
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "kubectl label namespace ${var.manifest_namespace} istio-injection=enabled --overwrite"
  }

  depends_on = [
    resource.google_gke_hub_feature_membership.feature_member,
    resource.null_resource.apply_kustomization
  ]
}
