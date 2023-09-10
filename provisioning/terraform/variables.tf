# Copyright 2023 Google LLC
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

# Required input variables
variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID to apply this config to"
}

variable "state_bucket_name" {
  type        = string
  description = "The GCS bucket URL where Terraform stores the state"
}

variable "configuration_path" {
  type        = string
  description = "Relative path to Cloud Ops Sandbox configuration"
  validation {
    condition     = can(regex("^configurations\\/((?!\\.\\.).)+$", var.configuration_path))
    error_message = "Path must start with 'configurations/' and cannot include parent redirects i.e. '..'"
  }
}

variable "state_prefix" {
  type        = string
  description = "Use to store multiple states when provisioning with the same state_bucket_name"
  default     = ""
}
