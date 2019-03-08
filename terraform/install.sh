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

#!/bin/bash

# This script provisions Hipster Shop Cluster for Stackdriver Sandbox usint Terraform

# Make sure Terraform is installed

# Make sure we use Application Default Credentials for authentication
# For that we need to unset GOOGLE_APPLICATION_CREDENTIALS and generate
# new default credentials by re-authenticating. Re-authentication
# is needed so we don't assume what's the current state on the machine that runs
# this script for Sandbox automation with terraform (idempotent automation)
export GOOGLE_APPLICATION_CREDENTIALS=""
gcloud auth application-default login

# Apply Terraform automation
terraform apply -auto-approve

