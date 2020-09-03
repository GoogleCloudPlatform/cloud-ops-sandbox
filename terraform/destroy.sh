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

# This script deletes the GCP project provisioned by Cloud Operations Sandbox

#set -euo pipefail
set -o errexit  # Exit on error
#set -x

log() { echo "$1" >&2;  }

IFS=$'\n'
acct=$(gcloud info --format="value(config.account)")

# ensure the working dir is the script's folder
SCRIPT_DIR=$(realpath $(dirname "$0"))
cd $SCRIPT_DIR

# For the purposes of telemetry
SESSION=$(python3 -c "import uuid; print(uuid.uuid4())")

sendTelemetry() {
  python3 telemetry.py --session=$SESSION --project_id=$1 --event=$2 --version=$VERSION
}

# find the cloud operations sandbox project id
filter=$(cat <<-END
  (id:cloud-ops-sandbox-* AND name='Cloud Operations Sandbox Demo')
  OR
  (id:stackdriver-sandbox-* AND name='Stackdriver Sandbox Demo')
END
)
found=$(gcloud projects list --filter="$filter" --format="value(projectId)")

# find projects owned by current user
for proj in ${found[@]}; do
  iam_test=$(gcloud projects get-iam-policy "$proj" \
               --flatten="bindings[].members" \
               --format="table(bindings.members)" \
               --filter="bindings.role:roles/owner" 2> /dev/null | grep $acct | cat)
  if [[ -n "$iam_test" ]]; then
    create_time=$(gcloud projects describe "$proj" --format="value(create_time.date(%b-%d-%Y))")
    owned_projects+=("$proj | [$create_time]")
  fi
done

# prompt user for a project to delete
if [[ -z "${owned_projects}" ]]; then
    log "error: no Cloud Operations Sandbox projects found"
    exit 1
else
    log "which Cloud Operations Sandbox project do you want to delete?:"
    select opt in $owned_projects "cancel"; do
        if [[ "${opt}" == "cancel" ]]; then
            exit 0
        elif [[ -z "${opt}" ]]; then
            log "invalid response"
        else
            PROJECT_ID=$(echo $opt | awk '{print $1}')
            break
        fi
    done
fi

# attempt deletion (tool will prompt user for confirmation)
log "attempting to delete $PROJECT_ID"
gcloud projects delete $PROJECT_ID


# if user backed out or deletion failed, stop script
found=$(gcloud projects list --filter="${PROJECT_ID}" --format="value(projectId)")
if [[ -n "${found}" ]]; then
    log "project $PROJECT_ID not deleted"
    sendTelemetry $PROJECT_ID sandbox-not-destroyed
    exit 1
fi

sendTelemetry $PROJECT_ID sandbox-destroyed
# remove tfstate file so a new project id will be generated next time
log "removing tfstate file"
rm -f .terraform/terraform.tfstate
log "Cloud Operations Sandbox resources deleted"
