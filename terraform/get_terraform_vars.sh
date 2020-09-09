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
#!/bin/bash

# Retrieve the cluster's external IP
TRIES=0
external_ip="";
while [[ -z $external_ip && "${TRIES}" -lt 20 ]]; do
    external_ip=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'); 
    [ -z "$external_ip" ] && sleep 5; 
    TRIES=$((TRIES + 1))
done;

if [[ -z $external_ip ]]; then
    echo "Error: No external IP address found."
fi

# Retrieve account email
acct=$(gcloud info --format="value(config.account)")

json_obj='{"external_ip": "%s", "email": "%s"}'
printf "$json_obj" "$external_ip" "$acct"