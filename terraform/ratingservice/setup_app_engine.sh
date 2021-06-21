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

ae_domain=$(gcloud app describe --project=$project_id --format="value(defaultHostname)" 2>/dev/null)
service_list=$(gcloud app services list --project=$project_id --filter="SERVICE=default" --format="value(SERVICE)" 2>/dev/null)

if [[ -n "$ae_domain" ]]; then
  default_service=false
  [[ -n "$service_list" ]] && default_service=true
  echo "{ \"application_exist\": \"true\", \"default_svc_exist\": \"$default_service\", \"application_domain\": \"$ae_domain\" }" | jq .
else
  echo "{ \"application_exist\": \"false\", \"default_svc_exist\": \"false\" }" | jq .
fi


