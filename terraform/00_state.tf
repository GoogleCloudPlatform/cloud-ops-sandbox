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

# Here we configure the state backend. For this demo we're using the "local"
# backend which stores everything in a local directory. The config you see below
# is functionally equivalent to the defaults.

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# TODO - Consider storing state remotely on a per-instance basis. 
# In that case we'd generate a backend config just before
# running terraform that would look something like this:

# terraform {
#   backend "gcs" {
#     bucket = "stackdriver-sandbox"
#     prefix = "<project-id>"
#   }
# }

# Interpolations are not supported in backend configs so we'd have to generate
# the file rather than rely on env vars like we can do almost everywhere else.
