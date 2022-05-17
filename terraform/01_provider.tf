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

# the `provider` block contains the configuration for the provider, including
# credentials and region config. It can be configured via environment variables
# or via passing a path to a credentials JSON file.

# In this demo we're using Application Default Creds instead, see this for
# details: https://cloud.google.com/docs/authentication/production
#
# TODO:  we can consider configuring it via env vars
# that were populated appropriately at runtime.
terraform {
  # The module has 0.12 syntax and is not compatible with any versions below 0.12.
  required_version = "~> 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "=3.90.0"
    }
    google-beta = {
      source  = "hashicorp/google"
      version = "=3.90.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 2.0"
    }

  }
}

provider "google" {
  project = var.project_id
}
