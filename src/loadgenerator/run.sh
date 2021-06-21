#!/bin/bash

# Copyright 2020 Google Inc. All rights reserved.
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

# ensure the working dir is the script's folder
SCRIPT_DIR=$(realpath $(dirname "$0"))
cd $SCRIPT_DIR

LOCUST_MODE=${LOCUST_MODE:-standalone}
LOCUST_TASK=${LOCUST_TASK:-basic}
LOCUS_OPTS="--task=$LOCUST_TASK --host=$TARGET_HOST"

if [[ "$LOCUST_MODE" = "master" ]]; then
    LOCUS_OPTS="$LOCUS_OPTS --master --master_sre_recipe"
elif [[ "$LOCUST_MODE" = "worker" ]]; then
    LOCUS_OPTS="$LOCUS_OPTS --worker --master_host=$LOCUST_MASTER"
    LOCUS_OPTS="$LOCUS_OPTS --worker_sre_recipe --master_host_sre_recipe=$LOCUST_MASTER"
fi

echo "python3 app.py $LOCUS_OPTS"

python3 app.py $LOCUS_OPTS
