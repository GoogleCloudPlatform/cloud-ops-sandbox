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

installTerraform()
{
  sudo apt-get install unzip
  wget https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip
  unzip terraform_0.11.11_linux_amd64.zip
  sudo install terraform /usr/local/bin
}

applyTerraform() {
  log "Initialize terraform state"
  terraform init

  log "Apply Terraform automation"
  terraform apply -auto-approve -var="billing_account=${billingAccounts[0]}"
}

getExternalIp() {
  external_ip=""; 
  while [ -z $external_ip ]; do
     log "Waiting for Hipster Shop endpoint..."; 
     external_ip=$(kubectl get svc frontend-external --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}"); 
     [ -z "$external_ip" ] && sleep 10; 
  done; 
  log "Hipster Shop Frontend is accessible at $external_ip"
}

# Install Load Generator service and start generating synthetic traffic to Sandbox
loadGen() {
  log "Running load generator"
  ../loadgenerator-tool startup --zone us-west2-a $external_ip
  # find the IP of the load generator web interface
  TRIES=0
  while [[ -z "${loadgen_ip}" && "${TRIES}" -lt 20  ]]; do
    log "waiting for load generator instance to spin up"
    sleep 1
    loadgen_ip=$(gcloud compute instances list --project "$created_project" \
                                               --filter="name:loadgenerator*" \
                                               --format="value(networkInterfaces[0].accessConfigs.natIP)")
    TRIES=$((TRIES + 1))
  done
}

displaySuccessMessage() {
    created_project=$(cat ./terraform.tfstate | \
                        grep "\"project\":" | \
                        grep -oh "stackdriver-sandbox-[0-9]*" | \
                        head -n 1)

    gcp_path="https://console.cloud.google.com/kubernetes/workload"
    if [[ -n "${created_project}" ]]; then
        gcp_path="$gcp_path?project=$created_project"
    fi

    if [[ -n "${loadgen_ip}" ]]; then
        loadgen_ip='http://$loadgen_ip'
    else
        loadgen_ip='[not found]'
    fi
    GREEN='\033[0;32m'
    COLOR_RESET='\033[0m'
    echo -e $GREEN
    log ""
    log ""
    log "--------------------------------------------------------------"
    log "Stackdriver Sandbox deployed successfully!"
    log ""
    log "     Stackdriver Dashboard: https://app.google.stackdriver.com/accounts/create"
    log "     Google Cloud Console Dashboard: $gcp_path"
    log "     Hipstershop web app address: http://$external_ip"
    log "     Locust load generator web interface: $loadgen_ip"
    echo -e $COLOR_RESET
}

log "Checking Prerequisites..."
log "Checking existence of billing accounts"
billingAccounts=$(gcloud beta billing accounts list --format="value(displayName)" --filter open=true)
if [ -z "$billingAccounts" ] || [[ ${#billingAccounts[@]} -eq 0 ]]
then
  log "No active billing accounts were detected. In order to create a project, Sandbox needs to have at least one billing account"
  log "Follow this link to setup a billing account:"
  log "https://cloud.google.com/billing/docs/how-to/manage-billing-account"
  log ""
  log "To list active billing accounts, run:"
  log "gcloud beta billing accounts list --filter open=true"

  exit;
elif [[ ${#billingAccounts[@]} -eq 1 ]]
then
  log "Billing account detected: '${billingAccounts[0]}'"
fi

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

