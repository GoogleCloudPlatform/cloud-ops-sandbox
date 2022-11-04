#!/usr/bin/env bash
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit  # exit on error
[ -n "${DEBUG+set}" ] && set -x # print tracing if DEBUG is set to any (even empty) value 

# ensure the working dir is the script's dir
SCRIPT_DIR=$(realpath $(dirname "$0"))
pushd $SCRIPT_DIR > /dev/null

# Log prints first argument to stderr
function Log {
  echo "$1" >&2;
}

# CheckEnvironment validates that necessary executables are in the path
function CheckEnvironment {
  local err=0
  gcloud --version > /dev/null 2>&1
  if [ "$?" -ne 0 ]; then
    err=1
    Log "Google Cloud CLI is not available"
  fi
  terraform --version > /dev/null 2>&1
  if [ "$?" -ne 0 ]; then
    err=1
    Log "Terraform is not available"
  fi
  #sandboxctl --version > /dev/null 2>&1
  #if [ "$?" -ne 0 ]; then
  #  err=1
  #  Log "sandboxctl is not available"
  #fi
  kubectl version --client=true > /dev/null 2>&1
  if [ "$?" -ne 0 ]; then
    err=1
    Log "kubectl is not available"
  fi
  jq --version > /dev/null 2>&1
  if [ "$?" -ne 0 ]; then
    err=1
    Log "jq is not available"
  fi

  if [ "$err" -eq 1 ]; then
    exit $err
  fi
}

# LogUsage() prints usage hint
function LogUsage {
  Log "install.sh command options"
  Log ""
  Log "commands:"
  Log "create       Creates Sandbox artifacts in the provided GCP project and configures them for the provided demo application"
  Log "create-all   Provisions Online Boutique application and creates Sandbox artifacts configured to work with it"
  Log "delete       Deletes all Sandbox artifacts created in the provided GCP project"
  Log ""
  Log "options:"
  Log "-p <id>|--project <id>   Google Cloud project ID where to install Cloud Ops Sandbox."
  Log "-app <id>|--app-id <id>  An application ID that identifies the Sandbox configuration."
  Log "--billing-acc <id>       A billing account to use with 'create-all' command to new created GCP project."
  Log "-v|--verbose             Prints execution trace (same as setting DEBUG environment variable)."
  Log "--ob-args <string>       A string of arguments to be used for Online Boutique installation. Use quotes"
  Log "                         to enclose arguments containing spaces (same as setting OB_ARGS environment variable)."
  Log ""
}

# ParseArguments(args...) parses script's execution parameters
function ParseArguments {
  project_id="$GOOGLE_CLOUD_PROJECT"
  ob_args="$OB_ARGS"
  
  while (( "$#" )); do
    case "$1" in
    create)
      command="create"
      shift
      ;;
    create-all)
      command="create-all"
      shift
      ;;
    delete)
      command="delete"
      shift
      ;;
    -p|--project)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        project_id=$2
        shift 2
      else
        Log "Error: Argument for $1 is missing"
        exit 1
      fi
      ;;
    -app|--app-id)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        app_id=$2
        shift 2
      else
        Log "Error: Argument for $1 is missing"
        exit 1
      fi
      ;;
    --billing-acc)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        billing_account=$2
        shift 2
      else
        Log "Error: Argument for $1 is missing"
        exit 1
      fi
      ;;
    --ob-args)
      if [ -n "$2" ]; then
        ob_args=$2
        shift 2
      fi
      ;;
    -v|--verbose)
      set -x
      shift
      ;;
    -h|--help)
      LogUsage;
      exit 0
      ;;
    -*|--*=) # unsupported flags
      Log "Error: Unsupported flag $1"
      exit 1
      ;;
    *) # ignore positional arguments
      shift
      ;;
    esac
  done

  # exit script if command is not defined
  if [ -z "$command" ]; then
    Log "Error: Please provide one of 'create' 'create-all' or 'delete' commands."
    exit 1
  fi

  # exit script if project is undefined and cannot be provisioned
  if [ -z "$project_id" ] && [ "$command" != "create-all" ]; then
    Log "Error: Project id is required to ${command} Cloud Ops Sandbox"
    exit 1
  fi
}

# AuthenticateToGCP() trigger GCloud CLI authentication if necessary
function AuthenticateToGCP {
  tries=0
  auth_result=$(gcloud --quiet auth list --format="value(account)")
  if [[ -z $auth_result ]]; then
      Log "Authentication failed"
      Log "Please allow gcloud and Cloud Shell to access your GCP account"
  fi
  while [[ -z $auth_result  && "${tries}" -lt 5  ]]; do
      auth_result=$(gcloud --quiet auth list --format="value(account)")
      sleep 1;
      tries=$((tries + 1))
  done
  if [[ -z $auth_result ]]; then
      Log "Error: Failed to authentication in front of Google Cloud"
      exit 1
  fi
}

# BillingAccountHelp() prints help in an event of billing account error
function BillingAccountHelp {
  Log "Error: no active billing accounts were detected. In order to create a sandboxed environment,"
  Log "the script needs to create a new GCP project and associate it with an active billing account"
  Log "Follow this link to setup a billing account:"
  Log "https://cloud.google.com/billing/docs/how-to/manage-billing-account"
  Log ""
  Log "To list active billing accounts, run:"
  Log "gcloud beta billing accounts list --filter open=true"
}

# SelectProject() helps a user to select a destination GCP project and set its id to $project_id
function SelectProject {
  if [ -n "$project_id" ]; then
      return
  fi

  Log "🔎 Checking for project list..."
  project_list=$(gcloud --quiet projects list --filter="project_id:cloud-ops-sandbox-*" --format="value(projectId)")

  # backup IFS is taken from https://unix.stackexchange.com/questions/264926/is-it-a-sane-approach-to-back-up-the-ifs-variable
  ${IFS+"false"} && unset saved_IFS || saved_IFS="$IFS" # backup IFS

  Log "☎️ Enter the number next to the project you would like to use (NOTE: you have to have Editor role or similar to use the project):"
  IFS=$'\n'
  select opt in "create a new project" ${found_projects[@]} "cancel"; do
    if [[ "${opt}" == "cancel" ]]; then
      exit 0
    elif [[ "${opt}" == "create a new project" ]]; then
      break
    elif [[ -z "${opt}" ]]; then
      Log "invalid response"
    else
      IFS=$' |'
      opt=($opt)
      project_id=${opt[0]}
      break
    fi
  done

  ${saved_IFS+"false"} && unset IFS || IFS="$saved_IFS" # restore IFS
}

# SelectBillingAccount() helps a user to select a billing account for a new GCP project and sets its id to $billing_account
function SelectBillingAccount {
  if [ -n "$billing_account" ]; then
    return
  fi

  Log "🔎 Checking available billing accounts..."
  local found_accounts=$(gcloud beta --quiet billing accounts list --format="value(displayName,name)" --filter open=true --sort-by=displayName)
  if [ -z "$found_accounts" ] || [[ ${#found_accounts[@]} -eq 0 ]]; then
    BillingAccountHelp
    exit 1
  fi

  # backup IFS is taken from https://unix.stackexchange.com/questions/264926/is-it-a-sane-approach-to-back-up-the-ifs-variable
  ${IFS+"false"} && unset saved_IFS || saved_IFS="$IFS" # backup IFS

  # map displayed name to account id
  declare -A map
  local selected_accounts=()
  IFS=$'\n'
  found_accounts=(found_accounts) # point to first account among found
  for acc in ${found_accounts[@]}; do
    IFS=$'\t'
    acc=($acc)
    IFS=$'\n'
    map[${acc[0]}]=${acc[1]}
  done

  Log "☎️ Enter the number next to the billing account you would like to use:"
  select opt in ${found_accounts} "cancel"; do
    if [[ "${opt}" == "cancel" ]]; then
      exit 0
    elif [[ -z "${opt}" ]]; then
      Log "invalid response"
    else
      local selection=${opt}
      billing_account=${map[$billing_acct]}
      break
    fi
  done

  ${saved_IFS+"false"} && unset IFS || IFS="$saved_IFS" # restore IFS
}

# ProvisionProject() helps to create a new GCP project
function ProvisionProject {
  if [ -z "$billing_account" ]; then
    SelectBillingAccount
  fi

  local identity=$(gcloud --quiet info --filter="status:active" --format="value(config.account)")
  # generate random id
  local id="cloud-ops-sandbox-$(od -N 4 -t uL -An /dev/urandom | tr -d " ")"
  # create project
  if [[ $identity == *"@google.com" ]]; then
    local yellow=`tput setaf 3`
    local revert=`tput sgr0`
    Log ""
    Log "${yellow}Note: your project will be created in the /untrusted/demos/cloud-ops-sandboxes folder."
    Log "${yellow}If you don't have access to this folder, please make sure to request at:"
    Log "${yellow}go/cloud-ops-sandbox-access"
    Log "${revert}"
    
    select opt in "continue" "cancel"; do
      if [[ "$opt" == "continue" ]]; then
        break;
      else
        exit 0;
      fi
    done
    local folder_id="470827991545" # /cloud-ops-sandboxes folder id
    gcloud --quiet projects create "$id" --name="Cloud Operations Sandbox Demo" --folder="$folder_id"
  else
    gcloud --quiet projects create "$id" --name="Cloud Operations Sandbox Demo"
  fi;
  if [ "$?" -eq 0 ]; then
    project_id="$id"
  else
    exit 1
  fi

  gcloud beta --quiet billing projects link "$project_id" --billing-account="$billing_account"
  if [ "$?" -ne 0 ]; then
    exit $?
  fi
}

# CheckOrCreateBucket(name) checks if a GCP bucket with the provided name exists and creates a new one if necessary
function CheckOrCreateBucket {
  local create_bucket=$1
  found_bucket=$(gcloud --quiet storage buckets list --project=$project_id --format="value(name)" --filter="name=$project_id-tf-state")
  if [ -n "$found_bucket" ]; then
    # remember the first found bucket
    found_bucket=($found_bucket)
    state_bucket_name=$found_bucket
  elif [ create_bucket ]; then
    # create new bucket
    gcloud --quiet storage buckets create "gs://$project_id-tf-state" --project=$project_id
    state_bucket_name="$project_id-tf-state"
  else
    Log "Error: Terraform state storage ($project_id-tf-state) is not found and cannot be created"
    exit 1
  fi
}

# SendTelemetry(operation) posts a telemetry message to PubSub
function SendTelemetry {
  if [ $COLLECT_USER_METRICS = "false" ]; then
    return
  fi

  local ops=$1
  local key=$(echo "${project_id}_CLOUDOPS_SANDBOX_${app_id}" | sha256sum --text | cut -d' ' -f1) # hash key is 64 digit presentation of SHA256

  # 'session' field is provided for backward compatability
  gcloud pubsub topics publish "telemetry_prod" --message="{\"session\": \"\",\"project\":\"${key}\",\"event\":\"${ops}\",\"datetime\":\"$(date --utc +%s.%N)\",\"version\":\"${sandbox_version}\"}" --project "stackdriver-sandbox-230822" --quiet 2> /dev/null
}

# RunTerraform(action) runs `apply` or `destroy` terraform command
function RunTerraform {
  local action=$1
  
  if [ ${action} != "apply" ] && [  ${action} != "destroy" ]; then
    return
  fi
  if [ ${action} = "apply" ]; then
    local operation="create-sandbox"
  else
    local operation="destroy-sandbox"
  fi

  # just in case there was a broken setup
  rm -rf .terraform/

  Log "🧭 initialize Terraform with GCS backend at gs://${bucket_name}"
  if terraform init -backend-config="bucket=$state_bucket_name" -backend-config="prefix=terraform/state_${SANDBOX_TERRAFORM_STATE_SUFFIX}" -lockfile=false 2> /dev/null; then
    Log ""
    Log "completed."
  else
    Log ""
    Log "Error: Credential check failed. Please, login with ADC to run terraform."
    gcloud auth application-default login
    if terraform init -backend-config="bucket=$state_bucket_name" -backend-config="prefix=terraform/state_${SANDBOX_TERRAFORM_STATE_SUFFIX}" -lockfile=false 2> /dev/null; then
      exit 1
    fi
  fi

  terraform ${action} -auto-approve \
      -var="project_id=${project_id}" \
      -var="state_bucket_name=${state_bucket_name}" \
      -var="cfg_file_location=${config_path}" \
      -var="state_suffix=${SANDBOX_TERRAFORM_STATE_SUFFIX}"
  SendTelemetry "${operation}"
}



###
# script execution starts below

ParseArguments $*;

Log "💿 checking installed software..."
CheckEnvironment;
Log "...done."

Log "🏗️ preparing script and environment..."
# read Sandbox metadata (note: project id can be not provided for 'create-all' command)
if [ -n "$project_id" ]; then
  metadata=$(gcloud --quiet compute project-info describe --project="$project_id" --format='value[](commonInstanceMetadata.items.sandbox-metadata)')
  if [ "$?" -eq 0 ] && [ -n "$metadata" ]; then
    sandbox_version=$(jq -r '."sandbox-version"' <<< "$metadata")
    stored_app_id=`jq -r '."app-id"' <<< "$metadata"`
    if [ -z "$app_id" ]; then
      app_id="$stored_app_id"
    fi
    if [ -z "${sandbox_version}" ] && [ -f "../versions.json" ]; then
      sandbox_version=$(jq -r '."version"' "../versions.json")
    fi
  fi
fi

# exit if app id is not defined
if [ -z "$app_id" ]; then
  Log "Error: Application id is missing"
  exit 1
fi

# do not allow installing Sandbox configuration over different Sandbox configuration (TODO: handle this case)
if [ -n "$stored_app_id" ] && [ "$app_id" != "$stored_app_id" ] && [ "$command" != "delete" ]; then
  Log "Warning: $project_id already has Sandbox configuration for $stored_app_id. Delete old Sandbox configuration first."
  exit 0
fi

AuthenticateToGCP;

if [ -z "$project_id" ] && [ "$command" = "create-all" ]; then
    SelectProject;
    if [ -z "$project_id" ]; then
      ProvisionProject
    fi
fi

# go to terraform directory one level up or one level down
[ -d "../terraform" ] && pushd ../terraform > /dev/null
[ -d "./terraform" ] && pushd ./terraform > /dev/null
if [ $(basename $(pwd)) != "terraform" ]; then
  Log "Error: cannot find Terraform configuration directory"
  exit 1
fi

# exit if app configuration directory does not exist
config_path=$(readlink -f "../apps/${app_id}")
if [ ! -d ${config_path} ]; then
  Log "Error: Application configuration directory ${config_path} does not exist"
  exit 1
fi
Log "...done."

case "$1" in
create)
  CheckOrCreateBucket true
  RunTerraform "apply"
  ;;
create-all)
  # (first implementation should exit with message "unsupported")
  # implement online boutique installation
  CheckOrCreateBucket true
  RunTerraform apply
  ;;
delete)
  CheckOrCreateBucket false; # do not create the bucket; state bucket has to be there
  # ensure that bucket exist and exit if it does not
  RunTerraform destroy
  ;;
esac

popd > /dev/null # restore directory before terraform
popd > /dev/null # restore original folder from which script was called
