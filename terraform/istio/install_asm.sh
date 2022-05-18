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
echo "### Begin install istio control plane"
echo "### "

# Set vars for DIRs
ISTIO_VERSION=1.7.1

# Set the working directory to our current directory (/sandbox/terraform/istio)
export SCRIPTPATH=$(dirname $(realpath $0))
cd $SCRIPTPATH
export WORK_DIR=$SCRIPTPATH

echo "Downloading Istio ${ISTIO_VERSION}..."
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -

echo "Moving istioctl into WORKDIR..."
mv istio-$ISTIO_VERSION/bin/istioctl ${WORK_DIR}

# Prepare for install
kubectl create namespace istio-system

cd ./istio-${ISTIO_VERSION}/
kubectl create secret generic cacerts -n istio-system \
    --from-file=samples/certs/ca-cert.pem \
    --from-file=samples/certs/ca-key.pem \
    --from-file=samples/certs/root-cert.pem \
    --from-file=samples/certs/cert-chain.pem

# cd back into istio/
cd ${WORK_DIR}

kubectl label namespace default istio-injection=enabled
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)

# Can also set flag here if values isn't actually being read...https://istio.io/v1.4/docs/setup/install/istioctl/
# install using operator config - https://istio.io/docs/setup/install/istioctl/#customizing-the-configuration
${WORK_DIR}/istioctl manifest install -f ${WORK_DIR}/istio_operator.yaml --skip-confirmation

# apply manifests
kubectl apply -f ${WORK_DIR}/../../istio-manifests
