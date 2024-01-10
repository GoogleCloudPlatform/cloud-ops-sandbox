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


module "asm" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/asm"

  project_id                = var.project_id
  cluster_name              = module.gke.name
  cluster_location          = module.gke.location
  enable_mesh_feature       = true
  enable_fleet_registration = true
  count                     = var.enable_asm == true ? 1 : 0
}
