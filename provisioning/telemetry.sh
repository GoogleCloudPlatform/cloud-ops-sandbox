#!/bin/bash
# Copyright 2023 Google LLC
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

obfuscate() {
    local value=$1
    local result=($(echo "${value}" | sha256sum))
    echo $result
}

# send_telemetry $session, $project_id, $event, $version
send_telemetry() {
    local timestamp=$(date --utc +%s.%N)
    local session=$1
    local project_id=$2
    project_id=$(obfuscate project_id)
    local event=$3
    local version=$3
    gcloud pubsub topics publish "telemetry_test" \
    --user-output-enabled=false \
    --project "stackdriver-sandbox-230822" \
    --message="{ \
    \"session\":\"$session\", \
    \"project\":\"$project_id\", \
    \"event\":\"$event\", \
    \"datetime\":\"$timestamp\", \
    \"version\":\"$version\"}"
}
