# Copyright 2020 Google LLC
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

# Creating this variable but leaving it empty means that the user will be
# prompted for a value when terraform is run

# Currently we need the user to provide some basic information to set up the monitoring examples
# These will be gone when we merge the monitoring terraform with the provisioning terraform
variable "external_ip" {
  type        = "string"
  description = "The external IP of the kubernetes cluster. Can be revealed by running kubectl get service frontend-external in Cloud CLI."
}

variable "project_id" {
  type        = "string"
  description = "The project id that was created by stackdriver sandbox."
}

variable "project_owner_email" {
	type	      = "string"
	description = "The email of the project owner."
}