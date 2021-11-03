/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "gcp_project_id" {
  type        = string
  description = "GCP project id where rating service should be provisioned."
}

variable "gcp_region_name" {
  type        = string
  default     = "us-east1"
  description = "GCP region name where CloudSQL instance and App Engine application should be deployed."
}
variable "service_name" {
  type        = string
  default     = "ratingservice"
  description = "App Engine service name"
}
variable "service_version" {
  type        = string
  default     = "prod"
  description = "App Engine service version"
}
