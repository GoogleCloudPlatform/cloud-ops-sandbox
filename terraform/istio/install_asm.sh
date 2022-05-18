# Copyright 2020 Google LLC
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

# Install Istio on the single cluster for Stackdriver Sandbox

# Download Istio

echo "### "
echo "### Begin install ASM control plane"
echo "### "


ASM_VERSION=1.12
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_ZONE=$(gcloud container clusters list --filter name=cloud-ops-sandbox --format="json" | jq -r '.[0].zone')

# Set the working directory to our current directory (/sandbox/terraform/istio)
export SCRIPTPATH=$(dirname $(realpath $0))
cd $SCRIPTPATH
export WORK_DIR=$SCRIPTPATH

echo "Downloading asmcli ${ASM_VERSION}..."
curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_${ASM_VERSION} > asmcli
chmod +x asmcli

echo "Installing ASM..."
./asmcli install \
  --project_id $PROJECT_ID \
  --cluster_name cloud-ops-sandbox \
  --cluster_location $CLUSTER_ZONE \
  --fleet_id $PROJECT_ID \
  --output_dir $WORK_DIR/asm_output \
  --enable_all \
  --option legacy-default-ingressgateway \
  --ca mesh_ca \
  --enable_gcp_components

echo "Installing Gateway..."
GATEWAY_NS=istio-gateway
kubectl create namespace $GATEWAY_NS
REVISION=$(kubectl get deploy -n istio-system -l app=istiod -o jsonpath={.items[*].metadata.labels.'istio\.io\/rev'}'{"\n"}')
kubectl label namespace $GATEWAY_NS istio.io/rev=$REVISION --overwrite
cd $WORK_DIR/asm_output
kubectl apply -n $GATEWAY_NS -f samples/gateways/istio-ingressgateway

echo "Enabling Sidecar Injection..."
cd $WORK_DIR
kubectl label namespace default istio-injection- istio.io/rev=$REVISION --overwrite
