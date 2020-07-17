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

# This script provisions Hipster Shop Cluster for Stackdriver Sandbox using Terraform

#set -euo pipefail
set -o errexit  # Exit on error
#set -o nounset  # Trigger error when expanding unset variables

# ensure the working dir is the script's folder
SCRIPT_DIR=$(realpath $(dirname "$0"))
cd $SCRIPT_DIR

log() { echo "$1" >&2; }

getBillingAccount() {
  log "Checking for billing accounts"
  found_accounts=$(gcloud beta billing accounts list --format="value(displayName)" --filter open=true)
  if [ -z "$found_accounts" ] || [[ ${#found_accounts[@]} -eq 0 ]]; then
    log "error: no active billing accounts were detected. In order to create a sandboxed environment,"
    log "the script needs to create a new GCP project and associate it with an active billing account"
    log "Follow this link to setup a billing account:"
    log "https://cloud.google.com/billing/docs/how-to/manage-billing-account"
    log ""
    log "To list active billing accounts, run:"
    log "gcloud beta billing accounts list --filter open=true"
    exit 1;
  elif [[ $(echo "${found_accounts}" | wc -l) -gt 1 ]]; then
      log "Which billing account would you like to use?:"
      IFS_bak=$IFS
      IFS=$'\n'
      select opt in ${found_accounts} "cancel"; do
        if [[ "${opt}" == "cancel" ]]; then
          exit 0
        elif [[ -z "${opt}" ]]; then
          log "invalid response"
        else
          billing_acct=$opt
          break
        fi
      done
      IFS=$IFS_bak
  else
    billing_acct=${found_accounts}
  fi
  log "using billing account: $billing_acct"
}

installTerraform() {
  sudo apt-get install unzip
  wget -q https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip -O ./terraform.zip
  unzip -o terraform.zip
  sudo install terraform /usr/local/bin
}

applyTerraform() {
  log "Initialize terraform state"
  terraform init

  log "Apply Terraform automation"
  terraform apply -auto-approve -var="billing_account=${billing_acct}"
  # find the name of the new project
  created_project=$(cat ./terraform.tfstate | \
                    grep "\"project\":" | \
                    grep -oh "stackdriver-sandbox-[0-9]*" | \
                    head -n 1)
}

getExternalIp() {
  external_ip=""; 
  while [ -z $external_ip ]; do
     log "Waiting for Hipster Shop endpoint..."; 
     external_ip=$(kubectl get svc frontend-external --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}"); 
     [ -z "$external_ip" ] && sleep 10; 
  done;
  if [[ $(curl -sL -w "%{http_code}"  "http://$external_ip" -o /dev/null) -eq 200 ]]; then
      log "Hipster Shop app is available at http://$external_ip"
  else
      log "error: Hipsterhop app at http://$external_ip is unreachable"
  fi
}

# Install Load Generator service and start generating synthetic traffic to Sandbox
loadGen() {
  log "Running load generator"
  ../loadgenerator/loadgen autostart $external_ip
  # find the IP of the load generator web interface
  TRIES=0
  while [[ $(curl -sL -w "%{http_code}"  "http://$loadgen_ip:8080" -o /dev/null --max-time 1) -ne 200  && \
      "${TRIES}" -lt 20  ]]; do
    log "waiting for load generator instance..."
    sleep 1
    loadgen_ip=$(gcloud compute instances list --project "$created_project" \
                                               --filter="name:loadgenerator*" \
                                               --format="value(networkInterfaces[0].accessConfigs.natIP)")
    TRIES=$((TRIES + 1))
  done
  if [[ $(curl -sL -w "%{http_code}"  "http://$loadgen_ip:8080" -o /dev/null  --max-time 1) -ne 200 ]]; then
    log "error: load generator unreachable"
  fi
}

displaySuccessMessage() {
    gcp_path="https://console.cloud.google.com"
    if [[ -n "${created_project}" ]]; then
        gcp_kubernetes_path="$gcp_path/kubernetes/workload?project=$created_project"
        gcp_monitoring_path="$gcp_path/monitoring?project=$created_project"
    fi

    if [[ -n "${loadgen_ip}" ]]; then
        loadgen_addr="http://$loadgen_ip:8080"
    else
        loadgen_addr="[not found]"
    fi
    log ""
    log ""
    log "********************************************************************************"
    log "Stackdriver Sandbox deployed successfully!"
    log ""
    log "     Google Cloud Console KBE Dashboard: $gcp_kubernetes_path"
    log "     Google Cloud Console Monitoring Workspace: $gcp_monitoring_path"
    log "     Hipstershop web app address: http://$external_ip"
    log "     Load generator web interface: $loadgen_addr"
    log "********************************************************************************"
}

log "Checking Prerequisites..."
getBillingAccount;

log "Make sure Terraform is installed"
if ! [ -x "$(command -v terraform)" ]; then
  log "Terraform is not installed. Trying to install it."
  installTerraform
fi

# Make sure we use Application Default Credentials for authentication
# For that we need to unset GOOGLE_APPLICATION_CREDENTIALS and generate
# new default credentials by re-authenticating. Re-authentication
# is needed so we don't assume what's the current state on the machine that runs
# this script for Sandbox automation with terraform (idempotent automation)
#export GOOGLE_APPLICATION_CREDENTIALS=""
#gcloud auth application-default login

# Ensure no google.com accounts early - they are not supported!
acct=$(gcloud info --format="value(config.account)")
if [[ $acct == *"google.com"* ]];
then
  log "Google.com accounts are currently not supported by Stackdriver Sandbox.";
  exit;
fi;

# Provision Stackdriver Sandbox cluster
applyTerraform;
getExternalIp;
loadGen;
displaySuccessMessage;

