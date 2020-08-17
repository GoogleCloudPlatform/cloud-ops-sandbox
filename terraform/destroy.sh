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

# This script deletes the GCP project provisioned by Cloud Ops Sandbox

#set -euo pipefail
set -o errexit  # Exit on error
#set -x

log() { echo "$1" >&2;  }

# ensure the working dir is the script's folder
SCRIPT_DIR=$(realpath $(dirname "$0"))
cd $SCRIPT_DIR

# find the cloud ops sandbox project id
found=$(gcloud projects list --filter="id:cloud-ops-sandbox-* AND name='Cloud Ops Sandbox Demo'" --format="value(projectId)")
if [[ -z "${found}" ]]; then
    log "error: no Cloud Ops Sandbox projects found"
    exit 1
elif [[ $(echo ${found} | wc -w) -gt 1 ]]; then
    log "which Cloud Ops Sandbox project do you want to delete?:"
    select opt in $found "cancel"; do
        if [[ "${opt}" == "cancel" ]]; then
            exit 0
        elif [[ -z "${opt}" ]]; then
            log "invalid response"
        else
            PROJECT_ID=$opt
            break
        fi
    done
else
    PROJECT_ID=$found
fi

# attempt deletion (tool will prompt user for confirmation)
log "attempting to delete $PROJECT_ID"
gcloud projects delete $PROJECT_ID


# if user backed out or deletion failed, stop script
found=$(gcloud projects list --filter="${PROJECT_ID}" --format="value(projectId)")
if [[ -n "${found}" ]]; then
    log "project $PROJECT_ID not deleted"
    exit 1
fi

# remove tfstate file so a new project id will be generated next time
log "removing tfstate file"
rm -f .terraform/terraform.tfstate
log "Cloud Ops Sandbox resources deleted"
