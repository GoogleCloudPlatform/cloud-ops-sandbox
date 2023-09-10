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

locals {
  validated_configuration_path = (endswith(var.configuration_path, "/")
    ? substr(var.configuration_path, 0, -1) : var.configuration_path
  )
  template_vars = {
    project_id       = var.gcp_project_id
    configuration_id = basename(local.validated_configuration_path)
    # allow using prefix for terraform state as suffix in the resource names
    state_suffix = var.state_prefix
  }
}
