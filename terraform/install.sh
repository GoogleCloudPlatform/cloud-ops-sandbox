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

create_flag=false

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
  fi

  # store (name:id) info in a map
  IFS_bak=$IFS
  declare -A map
  acc_ids=$(gcloud beta billing accounts list --format="value(displayName,name)" --filter open=true)
  IFS=$'\n'
  acc_ids=($acc_ids)
  for acc in ${acc_ids[@]}
  do
    IFS=$'\t'
    acc=($acc)
    IFS=$'\n'
    map[${acc[0]}]=${acc[1]}
  done

  if [[ $(echo "${found_accounts}" | wc -l) -gt 1 ]]; then
      log "Which billing account would you like to use?:"
      IFS=$'\n'
      select opt in ${found_accounts} "cancel"; do
        if [[ "${opt}" == "cancel" ]]; then
          exit 0
        elif [[ -z "${opt}" ]]; then
          log "invalid response"
        else
          billing_acct=${opt}
          billing_id=${map[$billing_acct]}
          break
        fi
      done
  else
    billing_acct=${found_accounts}
    billing_id=${map[$found_accounts]}
  fi
  IFS=$IFS_bak
  log "using billing account: $billing_acct"
  log "id: $billing_id"
}

getProject() {
  log "Checking for project list"
  found_projects=$(gcloud projects list --filter="name:stackdriver-sandbox-*" --format="value(projectId)")
  if [ -z "$found_projects" ] || [[ ${#found_projects[@]} -eq 0 ]]; then
    create_flag=true
  else
      log "Which project would you like to use?:"
      IFS_bak=$IFS
      IFS=$'\n'
      select opt in ${found_projects} "create a new Sandbox" "cancel"; do
        if [[ "${opt}" == "cancel" ]]; then
          exit 0
        elif [[ "${opt}" == "create a new Sandbox" ]]; then
          create_flag=true
          log "create a new Sandbox!"
          break
        elif [[ -z "${opt}" ]]; then
          log "invalid response"
        else
          project_id=$opt
          bucket_name="$project_id-bucket"
          break
        fi
      done
      IFS=$IFS_bak
  fi
}

createProject() {
  if [ "$create_flag" = true ]; then
    # generate random id
    project_id="stackdriver-sandbox-$(od -N 4 -t uL -An /dev/urandom | tr -d " ")"
    bucket_name="$project_id-bucket"
    # create project
    if [ -z "$folder_id" ]; then
      gcloud projects create "$project_id" --name="Stackdriver Sandbox Demo"
    else
      gcloud projects create "$project_id" --name="Stackdriver Sandbox Demo" --folder="$folder_id"
    fi;
    # link billing account
    gcloud beta billing projects link "$project_id" --billing-account="$billing_id"
    # confirm billing account linked
    check_billing=$(gcloud beta billing projects list --billing-account="$billing_id" --format="value(project_id)" --filter="project_id:$project_id")
    while [ -z "$check_billing" ]; do
      log "waiting for billing account to be linked"
      sleep 1
    done;
    # create bucket
    gsutil mb -p "$project_id" "gs://$bucket_name"
    log "created project: $project_id"
    log "created bucket: $bucket_name"
  fi
}

installTerraform() {
  sudo apt-get install unzip
  wget -q https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_linux_amd64.zip -O ./terraform.zip
  unzip -o terraform.zip
  sudo install terraform /usr/local/bin
}

applyTerraform() {
  log "Initialize terraform state with bucket ${bucket_name}"
  # lock-free to prevent access fail
  terraform init -backend-config "bucket=${bucket_name}" -lock=false

  log "Apply Terraform automation"
  terraform apply -auto-approve -var="billing_account=${billing_acct}" -var="project_id=${project_id}" -var="bucket_name=${bucket_name}"
  # find the name of the new project
  #created_project=$(cat ./terraform.tfstate | \
  #                  grep "\"project\":" | \
  #                  grep -oh "stackdriver-sandbox-[0-9]*" | \
  #                  head -n 1)
}

getExternalIp() {
  external_ip=""; 
  while [ -z $external_ip ]; do
     log "Waiting for Hipster Shop endpoint..."; 
     external_ip=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'); 
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
    loadgen_ip=$(gcloud compute instances list --project "$project_id" \
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
    if [[ -n "${project_id}" ]]; then
        gcp_kubernetes_path="$gcp_path/kubernetes/workload?project=$project_id"
        gcp_monitoring_path="$gcp_path/monitoring?project=$project_id"
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

log "Install current version of Terraform"
#installTerraform

# Make sure we use Application Default Credentials for authentication
# For that we need to unset GOOGLE_APPLICATION_CREDENTIALS and generate
# new default credentials by re-authenticating. Re-authentication
# is needed so we don't assume what's the current state on the machine that runs
# this script for Sandbox automation with terraform (idempotent automation)
#export GOOGLE_APPLICATION_CREDENTIALS=""
#gcloud auth application-default login

acct=$(gcloud info --format="value(config.account)")
if [[ $acct == *"google.com"* ]];
then
  folder_id="262044416022"            
fi;

# Provision Stackdriver Sandbox cluster
getProject;
createProject;
applyTerraform;
getExternalIp;
loadGen;
displaySuccessMessage;

