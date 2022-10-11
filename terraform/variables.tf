# Copyright 2020 Google LLC
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


# We use gcs as our backend, so the state file will be stored
# in a storage bucket. Since the bucket must preexists, we will create 
# the project and bucket outside Terraform. Also since the configuration
# of bucket can't be a variable, we create an empty config and modify it
# in the data section.

variable "project_id" {
  type        = string
  description = "(required) Project id of the destination GCP project for Sandbox."
}

variable "state_bucket_name" {
  type        = string
  description = "(required) Case sensitive GCS bucket name to store Terraform state."
}

variable "cfg_file_location" {
  type        = string
  description = "(required) Absolute path to a folder where deployment configurations are stored."
}

variable "state_suffix" {
  type        = string
  default     = ""
  description = "(optional) Use unique suffix to store multiple Terraform state within the same GCS bucket."
}
