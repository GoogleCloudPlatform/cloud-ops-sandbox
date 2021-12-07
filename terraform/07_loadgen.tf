# Copyright 2020 Google LLC
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

module "loadgen" {
  source      = "./loadgen"
  count       = var.skip_loadgen ? 0 : 1
  external_ip = google_container_cluster.gke.endpoint
  project_id  = data.google_project.project.project_id
  depends_on  = [module.k8s_services]
}

