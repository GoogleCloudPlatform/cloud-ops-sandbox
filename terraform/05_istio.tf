# Copyright 2021 Google LLC
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

# Set current project
resource "null_resource" "current_project" {
  provisioner "local-exec" {
    command = "gcloud config set project ${data.google_project.project.project_id}"
  }
}

# Gets the default Compute Engine Service Account of GKE
data "google_compute_default_service_account" "default" {
  project = data.google_project.project.project_id
  depends_on = [
    google_container_cluster.gke,
    null_resource.current_project
  ]
}

# Create GSA/KSA binding: let IAM auth KSAs as a svc.id.goog member name
resource "google_service_account_iam_binding" "set_gsa_binding" {
  service_account_id = data.google_compute_default_service_account.default.name // google_service_account.set_gsa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${data.google_project.project.project_id}.svc.id.goog[default/default]"
  ]

  depends_on = [data.google_compute_default_service_account.default]
}

# Annotate KSA
resource "null_resource" "annotate_ksa" {
  triggers = {
    cluster_ep = google_container_cluster.gke.endpoint #kubernetes cluster endpoint
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials cloud-ops-sandbox --zone ${element(random_shuffle.zone.result, 0)} --project ${data.google_project.project.project_id}
      kubectl annotate serviceaccount --namespace default default iam.gke.io/gcp-service-account=${data.google_compute_default_service_account.default.email}
    EOT
  }

  depends_on = [google_service_account_iam_binding.set_gsa_binding]
}

# Install Istio into the GKE cluster
resource "null_resource" "install_istio" {
  provisioner "local-exec" {
    command = "./istio/install_istio.sh"
  }
  depends_on = [null_resource.annotate_ksa]
}
