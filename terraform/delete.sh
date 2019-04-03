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

# This script deletes the GCP project provisioned by Stackdriver Sandbox

#set -euo pipefail
set -o errexit  # Exit on error

log() { echo "$1" >&2;  }

get_project(){
    gcloud projects list --filter="name:stackdriver-sandbox-*" \
                         --format="value(projectId)"
}

# ensure the working dir is the script's folder
SCRIPT_DIR=$(realpath $(dirname "$0"))
cd $SCRIPT_DIR

PROJECT_ID=$(get_project)

# find and delete the Stackdriver Sandbox GCP project
if [[ -z $PROJECT_ID  ]]; then
    log "error: Stackdriver Sandbox project not found"
    exit 1
fi
log "attempting to delete $PROJECT_ID"
gcloud projects delete $PROJECT_ID


# if user backed out of project deletion, stop script
PROJECT_ID=$(get_project)
if [[ ! -z $PROJECT_ID  ]]; then
    log "project $PROJECT_ID not deleted"
    exit 1
fi

# remove tfstate file so a new project id will be generated next time
log "removing tfstate file"
if [[ -f "./terraform.tfstate"  ]]; then
    rm terraform.tfstate
fi
log "Stackdriver Sandbox resources deleted"
