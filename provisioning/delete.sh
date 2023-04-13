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

# ensure the working dir is the script's folder
SCRIPT_DIR=$(realpath $(dirname "$0"))
pushd $SCRIPT_DIR 2> /dev/null

x_usage() {
  cat << EOF
${SCRIPT_NAME}
usage: ${SCRIPT_NAME} [PARAMETER]...

Remove all resources of the Cloud Ops Sandbox in the Google Cloud project.

PARAMETERS:
  --cluster-location                  (Optional) Zone or region name where the
                                      Sandbox cluster was provisioned. Default
                                      value is us-central1 region.
  --cluster-name                      (Optional) The name of GKE cluster that
                                      was used in installation.
                                      Default is 'cloud-ops-sandbox'.
  --project                           Google Cloud Project ID that
                                      hosts Cloud Ops Sandbox.
  --terraform-prefix                  (Optional) Terraform state storage prefix
                                      that was used in installation.
                                      Default is ''.
  -v | --verbose                      (Optional) Prints out all commands.
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

apply_terraform() {
  info "🏁 Deleting Cloud Ops Sandbox with Online Boutique..."

  pushd "./terraform" 2> /dev/null
  rm -f .terraform/terraform.tfstate* 2> /dev/null

  terraform init -backend-config "bucket=${bucket_name}" -backend-config "prefix=${terraform_state_prefix}" -lockfile=false
  terraform_command="terraform apply destroy -auto-approve \
  -var=\"state_bucket_name=${bucket_name}\"
  -var=\"state_prefix=${terraform_state_prefix:-""}\"
  --var=\"gcp_project_id=${project_id}\""

  if [[ -n ${cluster_name} ]]; then
    terraform_command+=" --var=\"gke_cluster_name=${cluster_name}\""
  fi
  if [[ -n ${cluster_location} ]]; then
    terraform_command+=" --var=\"gke_cluster_location=${cluster_location}\""
  fi

  terraform_command+=" --var=\"filepath_manifest=../kustomize/online-boutique/\"" 
  # customize default node pool configuration (default is 4 instances of 'e2-standard-4' VMs)
  # the expected value is a fully formatted JSON string (see ./terraform/variables.tf for the schema)
  if [[ -n $CLOUDOPS_SANDBOX_POOL_CFG ]]; then
    terraform_command+=" -var=\"gke_node_pool=$ONLINE_BOUTIQUE_NODE_POOL_CFG\"" 
  fi

  eval $terraform_command

  info ""
  info "🏁 Cloud Ops Sandbox is deleted."

  popd 2> /dev/null
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

  if [[ -z "${project_id}" ]]; then
    info "[ERROR] You have to provide project ID of the project that hosts Cloud Ops Sandbox"
    exit 3
  fi
  if [[ -n "${project_id}" && -z "$(gcloud projects list --filter=project_id:${project_id})" ]]; then
    info "[ERROR] Project with project id '${project_id}' does not exist."
    exit 2
  fi
}

# check for command line arguments
parse_arguments $*;

# ensure gcloud and cloudshell are authenticated
check_authentication;

# clean up
apply_terraform

popd 2> /dev/null
