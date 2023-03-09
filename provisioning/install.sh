#!/bin/bash
# Copyright 2023 Google LLC
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

# This script provisions Hipster Shop Cluster for Cloud Operations Sandbox using Terraform
set -o errexit  # Exit on error
if [[ -n "$DEBUG" ]]; then set -x; fi


log() { echo "$1" >&2; }

source telemetry.sh

# ensure the working dir is the script's folder
SCRIPT_DIR=$(realpath $(dirname "$0"))
pushd $SCRIPT_DIR

# Set telemetry parameters
if [[ -z "$SESSION" ]]; then export SESSION=$(python3 -c "import uuid; print(uuid.uuid4())"); fi
if [[ -z "$VERSION" ]]; then export VERSION=$(cat version.txt | tr -d '\n'); fi

promptForBillingAccount() {
  log "Checking for billing accounts..."
  found_accounts=$(gcloud beta billing accounts list --format="value(displayName)" --filter="open=true" --sort-by=displayName)
  if [ -z "$found_accounts" ] || [[ ${#found_accounts[@]} -eq 0 ]]; then
    log "error: no active billing accounts were detected. In order to create a sandboxed environment,"
    log "the script needs to create a new GCP project and associate it with an active billing account"
    log "Follow this link to setup a billing account:"
    log "https://cloud.google.com/billing/docs/how-to/manage-billing-account"
    log ""
    log "To list active billing accounts, run:"
    log "gcloud beta billing accounts list --filter open=true"
    send_telemetry $SESSION "none" no-active-billing $VERSION
    exit 1;
  fi

  # store (name:id) info in a map
  IFS_bak=$IFS
  declare -A map
  acc_ids=$(gcloud beta billing accounts list --format="value(displayName,name)" --filter="open=true" --sort-by=displayName)
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

promptForProject() {
  log "Checking for project list..."
  acct=$(gcloud info --format="value(config.account)")
  # get projects associated with the billing account
  billed_projects=$(gcloud beta billing projects list --billing-account="$billing_id" --filter="project_id:cloud-ops-sandbox-*" --format="value(projectId)")
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
          project_id=${opt[0]} # remember selected project
          break
        fi
      done
      IFS=$IFS_bak
  fi
}

createProject() {
    # generate random id
    project_id="cloud-ops-sandbox-$(od -N 4 -t uL -An /dev/urandom | tr -d " ")"
    # create project
    if [[ $acct == *"google.com"* ]];
    then
      YELLOW=`tput setaf 3`
      REVERT=`tput sgr0`
      log ""
      log "${YELLOW}Note: your project will be created in the /untrusted/demos/cloud-ops-sandboxes folder."
      log "${YELLOW}If you don't have access to this folder, please make sure to request at:"
      log "${YELLOW}go/cloud-ops-sandbox-access"
      log "${REVERT}"
      send_telemetry $SESSION $project_id new-sandbox-googler $VERSION
      select opt in "continue" "cancel"; do
        if [[ "$opt" == "continue" ]]; then
          break;
        else
          exit 0;
        fi
      done
      folder_id="470827991545" # /cloud-ops-sandboxes
      gcloud projects create "$project_id" --name="Cloud Operations Sandbox Demo" --folder="$folder_id"
    else
      send_telemetry $SESSION $project_id new-sandbox-non-googler $VERSION
      gcloud projects create "$project_id" --name="Cloud Operations Sandbox Demo"
    fi;
    # link billing account
    gcloud beta billing projects link "$project_id" --billing-account="$billing_id"
}

getOrCreateBucket() {
  # bucket name should be globally unique
  bucket_name="$project_id-cloud-ops-sandbox-terraform-state"

  # check if bucket already exists
  if [[ -n "$(gcloud storage buckets list --filter=\'$bucket_name\' --project $project_id)" ]]; then
    log "Bucket $bucket_name already exists"
  else
    # create new bucket
    TRIES=0
    while [[ "$(gcloud storage buckets create gs://$bucket_name --project $project_id)" || "${TRIES}" -lt 5 ]]; do
      log "Checking if bucket $bucket_name exists..."
      if [[ -n "$(gcloud storage buckets list --filter=\'$bucket_name\' --project $project_id)" ]]; then
        log "Bucket $bucket_name created"
        break;
      else
        log "Bucket creation failed. retrying..."
        sleep 1
        TRIES=$((TRIES + 1))
      fi
    done
  fi
}

applyTerraform() {
  rm -f .terraform/terraform.tfstate.*

  log "🏁 Installing CloudOps Sandbox with Online Boutique..."

  pushd "./terraform"
  terraform init -reconfigure -backend-config "bucket=${bucket_name}" -backend-config "prefix=${terraform_state_prefix}" -lockfile=false #2> /dev/null
  terraform_command="terraform apply -auto-approve \
  -var=\"state_bucket_name=${bucket_name}\"
  -var=\"state_prefix=${terraform_state_prefix:-""}\"
  --var=\"gcp_project_id=${project_id}\""

  # customize ASM provisioning
  local ingress_path=""  
  if [[ -z "${skip_asm}" ]]; then
    terraform_command+=" --var=\"enable_asm=true\""
    ingress_path="with-ingress/"
  fi
  # customize Online Boutique deployment with/without load generator and with/without ASM ingress
  if [[ -z "${skip_loadgen}" ]]; then
    terraform_command+=" --var=\"filepath_manifest=../kustomize/online-boutique/${ingress_path}\"" 
  else
    terraform_command+=" --var=\"filepath_manifest=../kustomize/online-boutique/no-loadgenerator/${ingress_path}\"" 
  fi
  # customize region/zone location (default is 'us-central1')
  if [[ -n $CLOUDOPS_SANDBOX_LOCATION ]]; then
    terraform_command+=" --var=\"gke_cluster_location=${CLOUDOPS_SANDBOX_LOCATION}\""
  fi
  # customize default node pool configuration (default is 4 instances of 'e2-standard-4' VMs)
  # the expected value is a fully formatted JSON string (see ./terraform/variables.tf for the schema)
  if [[ -n $CLOUDOPS_SANDBOX_POOL_CFG ]]; then
    terraform_command+=" -var=\"gke_node_pool=$ONLINE_BOUTIQUE_NODE_POOL_CFG\"" 
  fi
  eval $terraform_command

  log ""
  log "🏁 Installation of CloudOps Sandbox is complete."

  external_ip=$(terraform output --raw frontend_external_ip)
  if [[ -z $external_ip ]]; then
    log "Could not retrieve external IP... skipping monitoring configuration."
    return 1
  fi
  popd
}

validateExternalIp() {
  log -n "Retrieving Online Boutique public endpoint.";
  while [ -z $external_ip ]; do
     log -n "."
     external_ip=$(kubectl get service frontend-external -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}');
     [ -z "$external_ip" ] && sleep 10;
  done;
  log ""
  if [[ -n "${external_ip}" ]] && [[ $(curl -sL -w "%{http_code}"  "http://$external_ip" -o /dev/null) -eq 200 ]]; then
      log "Hipster Shop app is available at http://$external_ip"
      send_telemetry $SESSION $project_id hipstershop-available $VERSION
  else
      log "error: Online Boutique app at http://$external_ip is unreachable"
      send_telemetry $SESSION $project_id hipstershop-unavailable $VERSION
  fi
}

displaySuccessMessage() {
    gcp_path="https://console.cloud.google.com"
    if [[ -n "${project_id}" ]]; then
        gcp_kubernetes_path="$gcp_path/kubernetes/workload?project=$project_id"
        gcp_monitoring_path="$gcp_path/monitoring?project=$project_id"
    fi

    log ""
    log ""
    log "********************************************************************************"
    log "Cloud Operations Sandbox deployed successfully!"
    log ""
    log "     Google Cloud Console GKE Dashboard: $gcp_kubernetes_path"
    log "     Google Cloud Console Monitoring Workspace: $gcp_monitoring_path"
    log "     Online Boutique web app address: http://$external_ip"
    log ""
    log "To remove the Sandbox once finished using it, run"
    log ""
    log "     sandboxctl destroy"
    log ""
    log "********************************************************************************"
}

checkAuthentication() {
    TRIES=0
    AUTH_ACCT=$(gcloud auth list --format="value(account)")
    if [[ -z $AUTH_ACCT ]]; then
        log "Authentication failed"
        log "Please allow gcloud and Cloud Shell to access your GCP account"
    fi
    while [[ -z $AUTH_ACCT  && "${TRIES}" -lt 300  ]]; do
        AUTH_ACCT=$(gcloud auth list --format="value(account)")
        sleep 1;
        TRIES=$((TRIES + 1))
    done
    if [[ -z $AUTH_ACCT ]]; then
        exit 1
    fi
}

parseArguments() {
  while (( "$#" )); do
    case "$1" in
    -p|--project|--project-id)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        project_id=$2
        shift 2
      else
        log "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --terraform-prefix)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        terraform_state_prefix=$2
        shift 2
      else
        log "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --skip-loadgenerator)
      skip_loadgen=1
      shift
      ;;
    --skip-asm)
      skip_asm=1
      shift
      ;;
    --service-wait)
      service_wait=1
      shift
      ;;
    -v|--verbose)
      set -x
      shift
      ;;
    -h|--help)
      log "Deploy Cloud Operations Sandbox to a GCP project"
      log ""
      log "options:"
      log "-p|--project|--project-id     GCP project to deploy Cloud Operations Sandbox to"
      log "-v|--verbose                  print commands as they run (set -x)"
      log "--skip-loadgenerator          Don't deploy a loadgenerator instance"
      log "--service-wait                Wait indefinitely for services to be detected by Cloud Monitoring"
      log ""
      exit 0
      ;;
    -*|--*=) # unsupported flags
      log "Error: Unsupported flag $1" >&2
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

# ensure gcloud and cloudshell are authenticated
checkAuthentication;

# prompt user for missing information
if [[ -z "$project_id" ]]; then
  promptForBillingAccount;
  promptForProject;
fi
getOrCreateBucket;

# deploy
applyTerraform;
getExternalIp;
displaySuccessMessage;

# restore to calling directory
popd