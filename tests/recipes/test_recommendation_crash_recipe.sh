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

set -e
echo "Testing Recommendation Crash SRE Recipe"

HTTP_ADDR=$(sandboxctl describe | grep "Hipstershop web app address" | awk '{ print $NF  }')
echo "Hipstershop endpoint: $HTTP_ADDR"

echo "- testing request before changes..."
curl --show-error --fail $HTTP_ADDR/product/OLJCESPC7Z | grep Typewriter

echo "- breaking sandbox..."
sandboxctl sre-recipes break recipe3
sleep 10

echo "- expecting to see 500 error..."
curl -I --no-fail $HTTP_ADDR/product/OLJCESPC7Z | grep "500 Internal Server Error" 

echo "- checking for expected recomendationservice log..."
kubectl logs deploy/recommendationservice server | grep "invalid literal for int() with base 10: '5.0'"

echo "- restoring sandbox"
sandboxctl sre-recipes restore recipe3
sleep 10

echo "- testing restored website..."
curl --show-error --fail $HTTP_ADDR/product/OLJCESPC7Z | grep Typewriter

echo "✓ Tests Passed"
