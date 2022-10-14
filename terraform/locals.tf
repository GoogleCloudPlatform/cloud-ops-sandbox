# Copyright 2022 Google LLC
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
  # Name suffix prefixed with dash for readability
  name_suffix = var.state_suffix != "" ? "-${var.state_suffix}" : ""

  # Map of vars to be used with templatefile() call to read configurations
  config_file_subsitutes = {
    project_id  = var.project_id
    name_suffix = local.name_suffix
  }
}

