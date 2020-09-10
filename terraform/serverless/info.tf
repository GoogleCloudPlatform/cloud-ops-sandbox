# Copyright 2019 Google LLC
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


# This file is just to provide necessary information to provision
# cloud sql and app engine. It should be removed later. 

terraform {
  backend "local" {
    path = "ratingservice.tfstate"
  }
}

provider "google" {
  version = "~> 3.0"
}

data "google_project" "project" {
  project_id = var.project_id
}

variable "project_id" {
  type        = string
  description = "The id of your project. Case-sensitive."
}

variable "bucket_name" {
  type        = string
  description = "The name of your bucket to store the state file. Case-sensitive."
}
