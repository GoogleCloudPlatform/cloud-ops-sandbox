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
set -x

HTTP_ADDR=$(sandboxctl describe | grep "Hipstershop web app address" | awk '{ print $NF  }')

# page should load and show a typewriter
curl --show-error --fail $HTTP_ADDR/product/OLJCESPC7Z | grep Typewriter
sandboxctl sre-recipes break recipe3
sleep 5
# page should now return a 500 server error
curl -I --no-fail $HTTP_ADDR/product/OLJCESPC7Z | grep "500 Internal Server Error" 
sandboxctl sre-recipes restore recipe3
sleep 5
# check for expected log in recommendationservice
kubectl logs deploy/recommendationservice server | grep "invalid literal for int() with base 10: '5.0'"
# after restoring, site should load properly again
curl --show-error --fail $HTTP_ADDR/product/OLJCESPC7Z | grep Typewriter
