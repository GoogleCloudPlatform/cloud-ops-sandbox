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
  log "Checking for billing accounts..."
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
      log "Enter the number next to the billing account you would like to use:"
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
}

getProject() {
  log "Checking for project list..."
  acct=$(gcloud info --format="value(config.account)")
  # get projects associated with the billing account
  billed_projects=$(gcloud beta billing projects list --billing-account="$billing_id" --filter="project_id:stackdriver-sandbox-*" --format="value(projectId)")
  for proj in ${billed_projects[@]}; do
    # check if user is owner
    iam_test=$(gcloud projects get-iam-policy "$proj" \
                 --flatten="bindings[].members" \
                 --format="table(bindings.members)" \
                 --filter="bindings.role:roles/owner" 2> /dev/null | grep $acct | cat)
      if [[ -n "$iam_test" ]]; then
      create_time=$(gcloud projects describe "$proj" --format="value(create_time.date(%b-%d-%Y))")
      found_projects+=("$proj | [$create_time]")
    fi
  done

  # prompt user to choose a project
  if [ -z "$found_projects" ] || [[ ${#found_projects[@]} -eq 0 ]]; then
    createProject;
  else
      log "Enter the number next to the project you would like to use:"
      IFS_bak=$IFS
      IFS=$'\n'
      select opt in "create a new Sandbox" ${found_projects[@]} "cancel"; do
        if [[ "${opt}" == "cancel" ]]; then
          exit 0
        elif [[ "${opt}" == "create a new Sandbox" ]]; then
          log "create a new Sandbox!"
          createProject;
          break
        elif [[ -z "${opt}" ]]; then
          log "invalid response"
        else
          IFS=$' |'
          opt=($opt)
          project_id=${opt[0]}
          bucket_name="$project_id-bucket"
          break
        fi
      done
      IFS=$IFS_bak
  fi
}

createProject() {
    # generate random id
    project_id="stackdriver-sandbox-$(od -N 4 -t uL -An /dev/urandom | tr -d " ")"
    bucket_name="$project_id-bucket" # bucket name should be globally unique
    # create project
    if [[ $acct == *"google.com"* ]];
    then
      log ""
      log "Note: your project will be created in the /experimental-gke folder."
      log "If you don't have access to this folder, please make sure to request at:"
      log "go/experimental-folder-access"
      log ""
      select opt in "continue" "cancel"; do
        if [[ "$opt" == "continue" ]]; then
          break;
        else
          exit 0;
        fi
      done
      folder_id="262044416022" # /experimental-gke  
      gcloud projects create "$project_id" --name="Stackdriver Sandbox Demo" --folder="$folder_id"    
    else
      gcloud projects create "$project_id" --name="Stackdriver Sandbox Demo"      
    fi;
    # link billing account
    gcloud beta billing projects link "$project_id" --billing-account="$billing_id"
    # create bucket
    gcloud config set project "$project_id"
    TRIES=0
    while [[ $(gsutil mb -p "$project_id" "gs://$bucket_name") || "${TRIES}" -lt 5 ]]; do
      log "Check if bucket is created..."
      if [[ -n "$(gsutil ls)" ]]; then
        log "It's created!"
        break;
      else
        log "Creating bucket failed. Try to create it again..."
        sleep 1
        TRIES=$((TRIES + 1))
      fi
    done    
}

applyTerraform() {
  rm -f .terraform/terraform.tfstate

  log "Initialize terraform backend with bucket ${bucket_name}"  
  
  if terraform init -backend-config "bucket=${bucket_name}" -lock=false 2> /dev/null; then
    log "Credential check OK..."
  else
    log ""
    log "Credential check failed. Please login..."
    gcloud auth application-default login
    terraform init -backend-config "bucket=${bucket_name}" -lock=false # lock-free to prevent access fail
  fi

  log "Apply Terraform automation"
  terraform apply -auto-approve -var="billing_account=${billing_acct}" -var="project_id=${project_id}" -var="bucket_name=${bucket_name}"
}

installMonitoring() {
  log "Retrieving the external IP address of the application..."
  TRIES=0
  external_ip="";
  while [[ -z $external_ip && "${TRIES}" -lt 20 ]]; do
     external_ip=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'); 
     [ -z "$external_ip" ] && sleep 5; 
     TRIES=$((TRIES + 1))
  done;

  if [[ -z $external_ip ]]; then
    log "Could not retrieve external IP... skipping monitoring configuration."
    return 1
  fi

  gcp_monitoring_path="https://console.cloud.google.com/monitoring?project=$project_id"
  log "Please create a monitoring workspace for the project by clicking on the following link: $gcp_monitoring_path"
  read -p "When you are done, please press enter to continue"

  log "Creating monitoring examples (dashboards, uptime checks, alerting policies, etc.)..."
  pushd monitoring/
  terraform init -lock=false
  terraform apply --auto-approve -var="project_id=${project_id}" -var="external_ip=${external_ip}"
  popd
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

checkAuthentication() {
    TRIES=0
    AUTH_ACCT=$(gcloud auth list --format="value(account)")
    if [[ -z $AUTH_ACCT ]]; then
        log "Authentication failed"
        log "Please allow gcloud and Cloud Shell to access your GCP account"
    fi
    while [[ -z $AUTH_ACCT  && "${TRIES}" -lt 10  ]]; do
        AUTH_ACCT=$(gcloud auth list --format="value(account)")
        sleep 3;
        TRIES=$((TRIES + 1))
    done
    if [[ -z $AUTH_ACCT ]]; then
        exit 1
    fi
}

log "Checking Prerequisites..."
checkAuthentication;
getBillingAccount;

# Make sure we use Application Default Credentials for authentication
# For that we need to unset GOOGLE_APPLICATION_CREDENTIALS and generate
# new default credentials by re-authenticating. Re-authentication
# is needed so we don't assume what's the current state on the machine that runs
# this script for Sandbox automation with terraform (idempotent automation)
#export GOOGLE_APPLICATION_CREDENTIALS=""
#gcloud auth application-default login

# Provision Stackdriver Sandbox cluster
getProject;
applyTerraform;
# || true to prevent errors during monitoring setup from stopping the installation script
installMonitoring || true;
getExternalIp;
loadGen;
displaySuccessMessage;

