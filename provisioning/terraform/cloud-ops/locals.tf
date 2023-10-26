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
  default_template_vars = {
    project_id       = var.gcp_project_id
    configuration_id = basename(var.configuration_filepath)
  }
  template_vars = merge(local.default_template_vars, var.additional_configuration_vars)

  # Uptime checks
  uptimechecks_raw_data = yamldecode(file("${var.configuration_filepath}/uptimechecks.yaml"))
  uptimechecks_all_data = yamldecode(templatefile("${var.configuration_filepath}/uptimechecks.yaml", local.template_vars))
  uptimechecks          = { for c in local.uptimechecks_all_data.checks : c.name => c }
}
