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

/*
 * Custom function implemented via sub-module due the lack of
 * support for custom functions in Terraform.
 * Usage:
    module "my_service" {
      source = "./slo_service"
      project_number = "123456"
      name = "my-service"
      namespace = "service-namespace"
    }
  . . .
  # retrieve unique service ID
  module.slo_service.my_service.id
 */
variable "project_number" {
  type        = string
  description = "The GCP project number"
}

variable "name" {
  type        = string
  description = "ID of the monitored service"
}

variable "namespace" {
  type    = string
  default = "default"
}

locals {
  url            = "https://monitoring.googleapis.com/v3"
  project        = "projects/${var.project_number}"
  id             = "canonical-ist:proj-${var.project_number}-${var.namespace}-${var.name}"
  qualified_name = "${local.project}/services/${local.id}"
}

output "id" {
  value       = local.id
  description = "Canonical Istio service ID"
}

output "qualified_name" {
  value       = local.qualified_name
  description = "Fully qualified service ID"
}

output "url" {
  value       = "${local.url}/${local.qualified_name}"
  description = "URL for get service Monitoring API"
}
