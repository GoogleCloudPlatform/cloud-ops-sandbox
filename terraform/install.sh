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

promptForBillingAccount() {
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
}

promptForProject() {
  log "Checking for project list"
  billed_projects=$(gcloud beta billing projects list --billing-account="$billing_id" --filter="project_id:stackdriver-sandbox-*" --format="value(projectId)")
  # only keep projects with name "Stackdriver Sandbox Demo"
  found_projects=()
  for bill_proj in ${billed_projects[@]}
  do
    if [[ -n $(gcloud projects describe "$bill_proj" | grep "Stackdriver Sandbox Demo") ]]; then
      create_time=$(gcloud projects describe "$bill_proj" | grep "createTime")
      found_projects+=("$bill_proj | $create_time")
    fi
  done

  if [ -z "$found_projects" ] || [[ ${#found_projects[@]} -eq 0 ]]; then
    createProject;
  else
      log "Which project would you like to use?:"
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
          break
        fi
      done
      IFS=$IFS_bak
  fi
  # attach to project
  gcloud config set project "$project_id"
}

getOrCreateBucket() {
    # bucket name should be globally unique
    bucket_name="$project_id-bucket"

    gcloud config set project "$project_id"
    TRIES=0
    while [[ $(gsutil mb -p "$project_id" "gs://$bucket_name") || "${TRIES}" -lt 5 ]]; do
      log "Check if bucket $bucket_name exists..."
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

createProject() {
    # generate random id
    project_id="stackdriver-sandbox-$(od -N 4 -t uL -An /dev/urandom | tr -d " ")"
    # create project
    acct=$(gcloud info --format="value(config.account)")
    if [[ $acct == *"google.com"* ]];
    then
      log ""
      log "Note: your project will be created in the /experimental-gke folder."
      log "If you don't have access to this folder, please make sure to request at:"
      log "https://sphinx.corp.google.com/sphinx/#accessChangeRequest:systemName=internal_google_cloud_platform_usage"
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
}

installTerraform() {
  log "Installing current version of Terraform"
  sudo apt-get install unzip
  wget -q https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_linux_amd64.zip -O ./terraform.zip
  unzip -o terraform.zip
  sudo install terraform /usr/local/bin
}

applyTerraform() {
  rm -f .terraform/terraform.tfstate

  log "Initialize terraform state with bucket ${bucket_name}"
  terraform init -backend-config "bucket=${bucket_name}" -lock=false # lock-free to prevent access fail

  log "Apply Terraform automation"
  terraform apply -auto-approve -var="billing_account=${billing_acct}" -var="project_id=${project_id}" -var="bucket_name=${bucket_name}"
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

parseArguments() {
while (( "$#" )); do
  case "$1" in
    -p|--project|--project-id)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        project_id=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -b|--billing|--billing-id)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        billing_id=$2
        billing_acct=$(gcloud beta billing accounts describe $billing_id --format="value(displayName)")
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # ignore positional arguments
      shift
      ;;
  esac
done
}

# check for command line arguments
parseArguments $*;

# prompt user for missing information
if [[ -z "$billing_id" || -z "$billing_acct" ]]; then
  promptForBillingAccount;
fi
if [[ -z "$project_id" ]]; then
  promptForProject;
fi

# deploy
installTerraform
getOrCreateBucket;
applyTerraform;
getExternalIp;
loadGen;
displaySuccessMessage;

