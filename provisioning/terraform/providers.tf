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


# We use gcs as our backend, so the state file will be stored
# in a storage bucket. Since the bucket must preexists, we will create 
# the project and bucket outside Terraform. Also since the configuration
# of bucket can't be a variable, we create an empty config and modify it
# in the data section.

terraform {
  # The module has 0.12 syntax and is not compatible with any versions below 0.12.
  required_version = "~> 1.3.1"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.54.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.54.0"
    }
  }
  backend "gcs" {}
}

provider "google" {
  project = var.gcp_project_id
}

provider "google-beta" {
  project = var.gcp_project_id
}

data "terraform_remote_state" "state" {
  backend = "gcs"
  config = {
    bucket = var.state_bucket_name
    prefix = var.state_prefix
  }
}