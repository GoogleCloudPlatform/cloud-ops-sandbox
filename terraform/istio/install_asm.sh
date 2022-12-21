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
  --option prometheus-and-stackdriver \
  --option legacy-default-ingressgateway \
  --ca mesh_ca \
  --enable_gcp_components \
  --managed \
  --channel regular \
  --use_managed_cni

echo "Setting up Ingress Gateway"
kubectl create ns asm-ingress
kubectl label namespace asm-ingress istio-injection=enabled --overwrite

# sed commands to alter min and max replicas as well as cpu consumption for labs...
sed -i 's/minReplicas: 3/minReplicas: 1/g' $WORK_DIR/asm_output/samples/gateways/istio-ingressgateway/deployment.yaml
sed -i 's/maxReplicas: 5/maxReplicas: 1/g' $WORK_DIR/asm_output/samples/gateways/istio-ingressgateway/deployment.yaml
sed -i 's/replicas: 3/replicas: 1/g' $WORK_DIR/asm_output/samples/gateways/istio-ingressgateway/deployment.yaml
sed -i 's/cpu: 2000m/cpu: 200m/g' $WORK_DIR/asm_output/samples/gateways/istio-ingressgateway/deployment.yaml
sed -i 's/memory: 1024Mi/memory: 256Mi/g' $WORK_DIR/asm_output/samples/gateways/istio-ingressgateway/deployment.yaml

kubectl apply -n asm-ingress -f $WORK_DIR/asm_output/samples/gateways/istio-ingressgateway

echo "Enabling Sidecar Injection..."
kubectl label namespace default istio-injection=enabled --overwrite

echo "Deploying Virtual Services..."
cd $WORK_DIR
kubectl apply -f ../../istio-manifests
