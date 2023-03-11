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
variable "frontend_external_ip" {
  type        = string
  description = "Publicly available IP of the frontend service"
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.frontend_external_ip))
    error_message = "The value should be a valid IPv4 address"
  }
}

variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID to apply this config to"
}

# Optional input variables
variable "filepath_configuration" {
  type        = string
  description = "Path to monitoring resource configuration files. Relative path should be defined relative to the root terraform folder."
  default     = "../configurations/online-boutique"
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
    condition     = can(regex("^[\\w_-]{1,100}$", var.name_suffix))
    error_message = "The value should be a valid email address"
  }
  default = ""
}
