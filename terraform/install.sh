#!/bin/bash
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

# This script provisions Hipster Shop Cluster for Cloud Operations Sandbox using Terraform
#set -euo pipefail
set -o errexit  # Exit on error
#set -o nounset  # Trigger error when expanding unset variables
if [[ -n "$DEBUG" ]]; then set -x; fi

# ensure the working dir is the script's folder
SCRIPT_DIR=$(realpath $(dirname "$0"))
cd $SCRIPT_DIR

# create variable for telemetry purposes if SESSION is not already set
# session is defined as the current "instance" in which the user is logged-in to Cloud Shell terminal, working with Sandbox
if [[ -z "$SESSION" ]]; then export SESSION=$(python3 -c "import uuid; print(uuid.uuid4())"); fi

log() { echo "$1" >&2; }

# this function sends de-identified information to the Google Cloud Platform database
# on what events occur in users' Sandbox projects for development purposes
sendTelemetry() {
  python3 telemetry.py --session=$SESSION --project_id=$1 --event=$2 --version=$VERSION
}

promptForBillingAccount() {
  log "Checking for billing accounts..."
  found_accounts=$(gcloud beta billing accounts list --format="value(displayName)" --filter open=true --sort-by=displayName)
  if [ -z "$found_accounts" ] || [[ ${#found_accounts[@]} -eq 0 ]]; then
    log "error: no active billing accounts were detected. In order to create a sandboxed environment,"
    log "the script needs to create a new GCP project and associate it with an active billing account"
    log "Follow this link to setup a billing account:"
    log "https://cloud.google.com/billing/docs/how-to/manage-billing-account"
    log ""
    log "To list active billing accounts, run:"
    log "gcloud beta billing accounts list --filter open=true"
    sendTelemetry "none" no-active-billing
    exit 1;
  fi

  # store (name:id) info in a map
  IFS_bak=$IFS
  declare -A map
  acc_ids=$(gcloud beta billing accounts list --format="value(displayName,name)" --filter open=true --sort-by=displayName)
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

  # check if bucket already exists
  gcloud config set project "$project_id"
  if [[ -n "$(gsutil ls | grep gs://$bucket_name/)" ]]; then
    log "Bucket $bucket already exists"
  else
    # create new bucket
    TRIES=0
    while [[ $(gsutil mb -p "$project_id" "gs://$bucket_name") || "${TRIES}" -lt 5 ]]; do
      log "Checking if bucket $bucket_name exists..."
      if [[ -n "$(gsutil ls | grep gs://$bucket_name/)" ]]; then
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
      sendTelemetry $project_id new-sandbox-googler
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
      sendTelemetry $project_id new-sandbox-non-googler
      gcloud projects create "$project_id" --name="Cloud Operations Sandbox Demo"
    fi;
    # link billing account
    gcloud beta billing projects link "$project_id" --billing-account="$billing_id"
}

applyTerraform() {
  rm -f .terraform/terraform.tfstate

  log "Initialize terraform backend with bucket ${bucket_name}"

  if terraform init -backend-config "bucket=${bucket_name}" -lockfile=false 2> /dev/null; then
    log "Credential check OK..."
  else
    log ""
    log "Credential check failed. Please login..."
    gcloud auth application-default login
    terraform init -backend-config "bucket=${bucket_name}" -lockfile=false # lock-free to prevent access fail
  fi

  log "Apply Terraform automation"
  if [[ -n "$billing_id" ]]; then
    terraform apply -auto-approve -var="billing_account=${billing_acct}" -var="project_id=${project_id}" -var="bucket_name=${bucket_name}" -var="skip_loadgen=${skip_loadgen:-false}"
  else
    terraform apply -auto-approve -var="project_id=${project_id}" -var="bucket_name=${bucket_name}"  -var="skip_loadgen=${skip_loadgen:-false}"
  fi
}

authenticateCluster() {
  CLUSTER_ZONE=$(gcloud container clusters list --filter="name:cloud-ops-sandbox" --project $project_id --format="value(zone)")
  gcloud container clusters get-credentials cloud-ops-sandbox --zone "$CLUSTER_ZONE"
  # Make alias for this kubectl context
  kubectx main=.
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

  acct=$(gcloud info --format="value(config.account)")

  log "Checking to make sure necessary Istio services are ready for monitoring"
  python3 monitoring/istio_service_setup.py $project_id $CLUSTER_ZONE $service_wait
  log "Creating monitoring examples (dashboards, uptime checks, alerting policies, etc.)..."
  pushd monitoring/
  terraform init -lockfile=false
  terraform apply --auto-approve -var="project_id=${project_id}" -var="external_ip=${external_ip}" -var="project_owner_email=${acct}" -var="zone=${CLUSTER_ZONE}"
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
      sendTelemetry $project_id hipstershop-available
  else
      log "error: Hipsterhop app at http://$external_ip is unreachable"
      sendTelemetry $project_id hipstershop-unavailable
  fi
}

# Start generating synthetic traffic to Sandbox for a few seconds then stop
# This produces initial interesting telemetry data for users to view
loadGen() {
  log "Running load generator"

  # authenticate to load generator cluster
  LOADGEN_ZONE=$(gcloud container clusters list --filter="name:loadgenerator" --project $project_id --format="value(zone)")
  gcloud container clusters get-credentials loadgenerator --zone "$LOADGEN_ZONE"
  kubectx loadgenerator=.

  # Kicks off initial load generation via a POST request to Locust web interface
  # This is because Locust currently doesn't support CLI and UI at the same time
  TRIES=0
  while [[ $(curl -XPOST -d "user_count=50&spawn_rate=10" http://$loadgen_ip/swarm -o /dev/null -w "%{http_code}" --max-time 1) -ne 200  && \
      "${TRIES}" -lt 20  ]]; do
    log "waiting for load generator instance..."
    sleep 10
    loadgen_ip=$(kubectl get service loadgenerator -o jsonpath='{.status.loadBalancer.ingress[0].ip}');
     [ -z "$loadgen_ip" ] && sleep 10;
    TRIES=$((TRIES + 1))
  done

  # Lets load generator run for a few seconds
  sleep 5

  # Ends initial load generation
  if [[ $(curl http://$loadgen_ip/stop -o /dev/null -w "%{http_code}") -ne 200 ]]; then
    log "Failed to stop initial load generation"
  fi
  # Return kubectl context to the main cluster and show this to the user
  kubectx main
  log $(kubectx)
}

displaySuccessMessage() {
    gcp_path="https://console.cloud.google.com"
    if [[ -n "${project_id}" ]]; then
        gcp_kubernetes_path="$gcp_path/kubernetes/workload?project=$project_id"
        gcp_monitoring_path="$gcp_path/monitoring?project=$project_id"
    fi

    if [[ -n "${loadgen_ip}" ]]; then
        loadgen_addr="http://$loadgen_ip"
        sendTelemetry $project_id loadgen-available
    else
        loadgen_addr="[not found]"
        sendTelemetry $project_id loadgen-unavailable
    fi
    log ""
    log ""
    log "********************************************************************************"
    log "Cloud Operations Sandbox deployed successfully!"
    log ""
    log "     Google Cloud Console KBE Dashboard: $gcp_kubernetes_path"
    log "     Google Cloud Console Monitoring Workspace: $gcp_monitoring_path"
    log "     Hipstershop web app address: http://$external_ip"
    if [[ -z "${skip_loadgen}" ]]; then
      log "     Load generator web interface: $loadgen_addr"
    fi
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
        gcloud config set project "$project_id"
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
authenticateCluster;
# || true to prevent errors during monitoring setup from stopping the installation script
installMonitoring || true;
getExternalIp;
if [[ -z "${skip_loadgen}" ]]; then
  loadGen;
fi
displaySuccessMessage;
