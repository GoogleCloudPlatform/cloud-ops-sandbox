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

SCRIPT_NAME="${0##*/}"; readonly SCRIPT_NAME

info() {
  echo "⚙️  ${SCRIPT_NAME}: ${1}" >&2
}

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

# ensure the working dir is the script's folder
SCRIPT_DIR=$(realpath $(dirname "$0"))
pushd $SCRIPT_DIR

# Set telemetry parameters
if [[ -z "$SESSION" ]]; then export SESSION=$(python3 -c "import uuid; print(uuid.uuid4())"); fi
if [[ -z "$VERSION" ]]; then export VERSION=$(cat version.txt | tr -d '\n'); fi

obfuscate() {
    local value=${1}
    local result=($(echo "${value}" | sha256sum))
    echo ${result}
}

# send_telemetry arg1=project_id, arg_2=event
send_telemetry() {
    local timestamp=$(date --utc +%s.%N)
    local project_id=$1
    project_id=$(obfuscate project_id)
    local event=$2
    gcloud pubsub topics publish "telemetry_test" \
    --user-output-enabled=false \
    --project "stackdriver-sandbox-230822" \
    --message="{ \
    \"session\":\"$SESSION\", \
    \"project\":\"$project_id\", \
    \"event\":\"$event\", \
    \"datetime\":\"$timestamp\", \
    \"version\":\"$VERSION\"}"
}

prompt_for_billing_account() {
  info "Checking for billing accounts..."
  found_accounts=$(gcloud beta billing accounts list --format="value(displayName)" --filter="open=true" --sort-by=displayName)
  if [ -z "$found_accounts" ] || [[ ${#found_accounts[@]} -eq 0 ]]; then
    info "error: no active billing accounts were detected. In order to create a"
    info "sandboxed environment, the script needs to create a new Google Cloud"
    info "project and associate it with an active billing account. Follow this"
    info "link to setup a billing account:"
    info "https://cloud.google.com/billing/docs/how-to/manage-billing-account"
    info ""
    info "To list active billing accounts, run:"
    info "gcloud beta billing accounts list --filter open=true"
    send_telemetry "none" no-active-billing
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
      info "Enter the number next to the billing account you would like to use:"
      IFS=$'\n'
      select opt in ${found_accounts} "cancel"; do
        if [[ "${opt}" == "cancel" ]]; then
          exit 0
        elif [[ -z "${opt}" ]]; then
          info "invalid response"
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

prompt_for_project() {
  info "Checking for project list..."
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
    create_project;
  else
      info "Enter the number next to the project you would like to use:"
      IFS_bak=$IFS
      IFS=$'\n'
      select opt in "create a new Sandbox" ${found_projects[@]} "cancel"; do
        if [[ "${opt}" == "cancel" ]]; then
          exit 0
        elif [[ "${opt}" == "create a new Sandbox" ]]; then
          info "create a new Sandbox!"
          createProject;
          break
        elif [[ -z "${opt}" ]]; then
          info "invalid response"
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

create_project() {
    # generate random id
    project_id="cloud-ops-sandbox-$(od -N 4 -t uL -An /dev/urandom | tr -d " ")"
    # create project
    if [[ $acct == *"google.com"* ]];
    then
      YELLOW=`tput setaf 3`
      REVERT=`tput sgr0`
      info ""
      info "${YELLOW}Note: your project will be created in the /untrusted/demos/cloud-ops-sandboxes folder."
      info "${YELLOW}If you don't have access to this folder, please make sure to request at:"
      info "${YELLOW}go/cloud-ops-sandbox-access"
      info "${REVERT}"
      send_telemetry $project_id new-sandbox-googler
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
      send_telemetry $project_id new-sandbox-non-googler
      gcloud projects create "$project_id" --name="Cloud Operations Sandbox Demo"
    fi;
    # link billing account
    gcloud beta billing projects link "$project_id" --billing-account="$billing_id"
}

get_create_bucket() {
  # bucket name should be globally unique
  bucket_name="$project_id-cloud-ops-sandbox-terraform-state"

  # check if bucket already exists
  if [[ -n "$(gcloud storage buckets list --filter=\'$bucket_name\' --project $project_id)" ]]; then
    info "Bucket $bucket_name already exists"
  else
    # create new bucket
    TRIES=0
    while [[ "$(gcloud storage buckets create gs://$bucket_name --project $project_id)" || "${TRIES}" -lt 5 ]]; do
      info "Checking if bucket $bucket_name exists..."
      if [[ -n "$(gcloud storage buckets list --filter=\'$bucket_name\' --project $project_id)" ]]; then
        info "Bucket $bucket_name created"
        break;
      else
        info "Bucket creation failed. retrying..."
        sleep 1
        TRIES=$((TRIES + 1))
      fi
    done
  fi
}

apply_terraform() {
  info "🏁 Installing Cloud Ops Sandbox with Online Boutique..."

  pushd "./terraform"
  rm -f .terraform/terraform.tfstate* 2> /dev/null

  terraform init -backend-config "bucket=${bucket_name}" -backend-config "prefix=${terraform_state_prefix}" -lockfile=false
  terraform_command="terraform apply -auto-approve \
  -var=\"state_bucket_name=${bucket_name}\"
  -var=\"state_prefix=${terraform_state_prefix:-""}\"
  --var=\"gcp_project_id=${project_id}\""

  if [[ -n ${cluster_name} ]]; then
    terraform_command+=" --var=\"gke_cluster_name=${cluster_name}\""
  fi
  if [[ -n ${cluster_location} ]]; then
    terraform_command+=" --var=\"gke_cluster_location=${cluster_location}\""
  fi

  # customize ASM provisioning
  local ingress_path=""  
  if [[ -z "${skip_asm}" ]]; then
    terraform_command+=" --var=\"enable_asm=true\""
  else
    terraform_command+=" --var=\"enable_asm=false\""
  fi
  # customize Online Boutique deployment with/without load generator and with/without ASM ingress
  local ob_kpath="../kustomize/online-boutique/"

  # patch kustomize config
  cp "${ob_kpath}kustomization.yaml" "${ob_kpath}kustomization.yaml.bak" 2> /dev/null
  local sed_expression=""
  # uncomment 'without-loadgenerator' component if skip_loadgen is set
  if [[ -n "${skip_loadgen}" ]]; then
    sed_expression+=" -E '/without-loadgenerator(\?version\=v?[0-9]+\.[0-9]+\.[0-9]+)?$/s/^#//'"
  fi
  # uncomment 'service-mesh-istio' component if skip_asm is NOT set
  if [[ -z "${skip_asm}" ]]; then
    sed_expression+=" -E '/service-mesh-istio(\?version\=v?[0-9]+\.[0-9]+\.[0-9]+)?$/s/^#//'"
  fi
  if [[ -n "${sed_expression}" ]]; then
    eval "sed ${sed_expression} ${ob_kpath}kustomization.yaml.bak > ${ob_kpath}kustomization.yaml"
  fi

  terraform_command+=" --var=\"filepath_manifest=${ob_kpath}\"" 
  # customize default node pool configuration (default is 4 instances of 'e2-standard-4' VMs)
  # the expected value is a fully formatted JSON string (see ./terraform/variables.tf for the schema)
  if [[ -n $CLOUDOPS_SANDBOX_POOL_CFG ]]; then
    terraform_command+=" -var=\"gke_node_pool=$ONLINE_BOUTIQUE_NODE_POOL_CFG\"" 
  fi

  trap "mv ${ob_kpath}kustomization.yaml.bak ${ob_kpath}kustomization.yaml 2> /dev/null" EXIT
  eval $terraform_command
  trap - EXIT

  # restore kustomize modifications and exit if error
  mv "${ob_kpath}kustomization.yaml.bak" "${ob_kpath}kustomization.yaml" 2> /dev/null

  info ""
  info "🏁 Installation of CloudOps Sandbox is complete."

  external_ip=$(terraform output --raw frontend_external_ip)
  if [[ -z $external_ip ]]; then
    info "Could not retrieve external IP... skipping monitoring configuration."
    return 1
  fi
  popd
}

x_usage() {
  cat << EOF
${SCRIPT_NAME}
usage: ${SCRIPT_NAME} [PARAMETER]...

Deploy Cloud Operations Sandbox to a Google Cloud project.

PARAMETERS:
  --cluster-location                  (Optional) Zone or region name where the
                                      cluster is provisioned. Default value is
                                      us-central1 region.
  --cluster-name                      (Optional) The name of GKE cluster.
                                      Default is 'cloud-ops-sandbox'.
  --project                           (Optional) Google Cloud Project ID that
                                      will host Cloud Ops Sandbox. If not
                                      provided, a new Google Cloud project will
                                      be created.
  --skip-asm                          (Optional) Set to not install Anthos
                                      Service Mesh. Default is false.
  --skip-loadgenerator                (Optional) Set to not deploy load
                                      generator. Default is false.
  --terraform-prefix                  (Optional) Customize Terraform state
                                      storage prefix to store multiple states
                                      in the same project. Default is ''.
  -v | --verbose                      (Optional) Prints out all commands.
EOF
}

x_success_message() {
  local gcp_path="https://console.cloud.google.com"
  local gcp_kubernetes_path="${gcp_path}/kubernetes/workload?project=${project_id}"
  local gcp_monitoring_path="${gcp_path}/monitoring?project=${project_id}"

  cat << EOF

********************************************************************************
Cloud Operations Sandbox deployed successfully!

     Google Cloud Console GKE Dashboard: ${gcp_kubernetes_path}
     Google Cloud Console Monitoring Workspace: ${gcp_monitoring_path}
     Try Online Boutique at http://${external_ip}

********************************************************************************
EOF
}

check_authentication() {
    TRIES=0
    AUTH_ACCT=$(gcloud auth list --format="value(account)")
    if [[ -z $AUTH_ACCT ]]; then
        info "Authentication failed"
        info "Please allow gcloud and Cloud Shell to access your Google Cloud account"
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

parse_arguments() {
  while (( "$#" )); do
    case "$1" in
    --cluster-name)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        cluster_name="${2}"
        shift 2
      else
        info "[ERROR] Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --cluster-location)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        cluster_location="${2}"
        shift 2
      else
        info "[ERROR] Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --project)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        project_id="${2}"
        shift 2
      else
        info "[ERROR] Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    --terraform-prefix)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        terraform_state_prefix="${2}"
        shift 2
      else
        info "[ERROR] Argument for $1 is missing" >&2
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
    -v|--verbose)
      set -x
      shift
      ;;
    -h|--help)
      x_usage
      exit 0
      ;;
    *)
      info "[WARNING] Unknown parameter $1"
      x_usage
      exit 2
      ;;
    esac
  done

  if [[ -n "${project_id}" && -z "$(gcloud projects list --filter=project_id:${project_id})" ]]; then
    info "[ERROR] Project with project ID '${project_id}' does not exist."
    exit 2
  fi
}

# check for command line arguments
parse_arguments $*;

# ensure gcloud and cloudshell are authenticated
check_authentication;

# prompt user for missing information
if [[ -z "$project_id" ]]; then
  prompt_for_billing_account;
  prompt_for_project;
fi
get_create_bucket;

# deploy
apply_terraform;
x_success_message;

# restore to calling directory
popd
