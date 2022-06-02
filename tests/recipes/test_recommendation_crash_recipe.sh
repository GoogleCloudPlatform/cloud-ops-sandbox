#!/bin/bash
# Copyright 2021 Google LLC
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

# add sandboxctl to path
SCRIPT_DIR=$(dirname $(realpath -s $0))
SRE_RECIPES_DIR=$(realpath $SCRIPT_DIR/../../sre-recipes)
export PATH=$PATH:$SRE_RECIPES_DIR

set -e
echo "Testing Recommendation Crash SRE Recipe"

HTTP_ADDR=$(sandboxctl describe | grep "Hipstershop web app address" | awk '{ print $NF  }')
echo "Hipstershop endpoint: $HTTP_ADDR"

echo "- testing request before changes..."
curl --show-error --fail $HTTP_ADDR/product/OLJCESPC7Z | grep Typewriter

echo "- breaking sandbox..."
sandboxctl sre-recipes break recipe3
broken_pod=$(kubectl get pods --sort-by=.status.startTime -o jsonpath="{.items[-1].metadata.name}")
kubectl wait --for=condition=ready --timeout=30s pod $broken_pod
sleep 10

echo "- expecting to see 500 error..."
curl -I --no-fail $HTTP_ADDR/product/OLJCESPC7Z | grep "500 Internal Server Error" 

echo "- checking for expected recomendationservice log..."
sleep 30
kubectl logs $broken_pod recommendationservice | grep "invalid literal for int() with base 10: '5.0'"

echo "- restoring sandbox"
sandboxctl sre-recipes restore recipe3
restored_pod=$(kubectl get pods --sort-by=.status.startTime -o jsonpath="{.items[-1].metadata.name}")
kubectl wait --for=condition=ready --timeout=120s pod $restored_pod
sleep 10

echo "- testing restored website..."
curl --show-error --fail $HTTP_ADDR/product/OLJCESPC7Z | grep Typewriter

echo "✓ Tests Passed"
