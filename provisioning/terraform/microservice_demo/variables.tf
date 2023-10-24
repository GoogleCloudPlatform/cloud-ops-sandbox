/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# Required input variables
variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID to apply this config to"
}

variable "enable_asm" {
  type        = bool
  description = "If true, installs Anthos Service Mesh (managed version of Istio) on the GKE cluster"
}

variable "manifest_filepath" {
  type        = string
  description = "Path to Kustomize manifest resource(s)"
}
