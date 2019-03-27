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
  while [ -z $external_ip ]; 
  do
     log "Waiting for Hipster Shop endpoint..."; 
     external_ip=$(kubectl get svc frontend-external --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}"); 
     [ -z "$external_ip" ] && sleep 10; 
  done; 

  log "Verifying that Hipster Shop Frontend is accessible"
  if [[ $(curl -sL -w "%{http code}\\n" "http://$external_ip" -o /dev/null) -eq 200 ]]
  then
    log "Stackdriver Sandbox cluster provisioning has completed successfully! Access it at http://$external_ip"
  fi
}

# Install Load Generator service and start generating synthetic traffic to Sandbox
loadGen() {
  log "Running load generator"
  ../loadgenerator/loadgenerator-tool autostart $external_ip
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

#log "**WARNING** Terraform script will create a Sandbox cluster. It asks for billing account"
#log "If you have not set up billing account or want to cancel the operation, choose 'N'."
#log ""
#log "To list active billing accounts, run:"
#log "gcloud beta billing accounts list --filter open=true"
#log
#while true; do
#    read -p "Do you wish to continue to cluster creation? y/n " yn
#    case $yn in
#        [Yy]* ) applyTerraform; getExternalIp; loadGen; break;;
#        [Nn]* ) exit;;
#        * ) echo "Please answer yes or no.";;
#    esac
#done
