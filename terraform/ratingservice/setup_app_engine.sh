#!/bin/bash
# 
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

#
# Print the following Json to STDOUT:
# {
#   "application_exist": <string>, // "true" or "false" showing whether App Engine application was already created
#   "application_domain": <string>, // describes application hostname if application_exist==true
#   "default_svc_exist": <string>  // "true" or "false" showing whether App Engine has default service
# }
#
# NOTE: Json has string values because Terraform data "external" does not know to parse non-string values

project_id=$1
ae_app_exist=false
service_exist=false

print_json_result() {
  if [ $ae_app_exist == true ]; then
    app_hostname=$(gcloud app describe --format=json --project=$project_id | jq .defaultHostname)
    echo "{ \"application_exist\": \"$ae_app_exist\", \"application_domain\": $app_hostname, \"default_svc_exist\": \"$service_exist\" }" | jq .
  else
    echo "{ \"application_exist\": \"$ae_app_exist\", \"default_svc_exist\": \"$service_exist\" }" | jq .
  fi
}

service_list=$(gcloud app services list --project=$project_id --filter="SERVICE:default" --format=json 2>/dev/null)
[ $? -eq 0 ] && ae_app_exist=true
[[ $(echo $service_list | jq length) = 1 ]] && service_exist=true
print_json_result



