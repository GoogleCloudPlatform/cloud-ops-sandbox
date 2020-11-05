/**
 * Copyright 2020 Google LLC
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

# Creating this variable but leaving it empty means that the user will be
# prompted for a value when terraform is run
variable "billing_account" {
  default     = null
  type        = string
  description = "The name of your billing account. Case-sensitive."
}

variable "project_id" {
  type        = string
  description = "The id of your project. Case-sensitive."
}

variable "bucket_name" {
  type        = string
  description = "The name of your bucket to store the state file. Case-sensitive."
}

variable "rating_service_region_name" {
  type        = string
  default     = "us-east1"
  description = "The region name where rating serverless microservice is deployed."
}

variable "enable_rating_service" {
  type        = bool
  default     = false
  description = "Temporary variable to allow disable (by default) provisioning of the rating service resources."
}
