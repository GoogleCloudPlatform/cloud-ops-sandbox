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

variable "enable_asm" {
  type        = bool
  description = "Flags to provision ASM related resources"
}

variable "configuration_filepath" {
  type        = string
  description = "Path to Cloud Ops Sandbox configuration for the demo application"
}

# Optional input variables
variable "additional_configuration_vars" {
  type        = map(string)
  description = "A map of variables that can be used to provision the configurations. By default only project id, configuration id and custom suffix (based on the state) are provided."
  default     = {}
}

variable "gke_cluster_name" {
  type        = string
  description = "Name given to the new GKE cluster"
  default     = "cloud-ops-sandbox"
}

variable "notification_channel_email" {
  type        = string
  description = "Email address to use for alert notification channel."
  validation {
    condition     = can(regex("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$", var.notification_channel_email))
    error_message = "The value should be a valid email address"
  }
  default = "devops@acme.com"
}

variable "name_suffix" {
  type        = string
  description = "Custom suffix to allow provisioning multiple copies of the resource within the same GCP project"
  validation {
    condition     = can(regex("^$|^[\\w_-]{1,100}$", var.name_suffix))
    error_message = "The value should be a valid email address"
  }
  default = ""
}
