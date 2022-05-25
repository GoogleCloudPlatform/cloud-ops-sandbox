#!/bin/bash
# Copyright 2022 Google LLC
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

# Run all tests to ensure environment is working as expected

set -o errexit  # Exit on error
#set -o nounset  # Trigger error when expanding unset variables
if [[ -n "$DEBUG" ]]; then set -x; fi

# ensure the working dir is the script's folder
SCRIPT_DIR=$(realpath $(dirname "$0"))
cd $SCRIPT_DIR

# set environment variables
export PROJECT_ID=$(gcloud config get-value project)
export ZONE=$(gcloud container clusters list --filter="name:cloud-ops-sandbox" --project ${PROJECT_ID} --format="value(zone)")
export LOADGEN_ZONE=$(gcloud container clusters list --filter="name:loadgenerator" --project ${PROJECT_ID} --format="value(zone)")

# run provisioning test
echo "running provisioning tests.."
python3 -m venv --system-site-packages provision-venv
source provision-venv/bin/activate
python3 -m pip install -r $SCRIPT_DIR/provisioning/requirements.txt
pushd $SCRIPT_DIR/provisioning
  python3 ./test_runner.py
popd
deactivate

# run monitoring integration tests
echo "running monitoring integration tests.."
python3 -m venv --system-site-packages monitor-venv
source monitor-venv/bin/activate
python3 -m pip install -r $SCRIPT_DIR/requirements.txt
python3 $SCRIPT_DIR/monitoring_integration_test.py ${PROJECT_ID}
deactivate

# run rating service tests
if [[ -z "$SKIP_RATINGS_TEST" ]]; then
  echo "running ratingservice tests.."
  RATING_SERVICE_URL="https://ratingservice-dot-$(gcloud app describe --format='value(defaultHostname)' --project=${PROJECT_ID})"
  python3 -m venv --system-site-packages ratings-venv
  source ratings-venv/bin/activate
  python3 -m pip install -r $SCRIPT_DIR/ratingservice/requirements.txt
  python3 $SCRIPT_DIR/ratingservice/main_test.py
  deactivate
else
  echo "rating test skipped"
fi

# run sre recipes tests
echo "running SRE recipes tests.."
$SCRIPT_DIR/recipes/test_recommendation_crash_recipe.sh

echo "✅ All tests pass"
