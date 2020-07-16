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
echo "### Begin install istio control plane - ${CONTEXT}"
echo "### "

# Set vars for DIRs
ISTIO_VERSION="${ISTIO_VERSION:-1.6.2}"
export WORK_DIR=`pwd`
export ISTIO_DIR=$WORK_DIR/istio-$ISTIO_VERSION
export BASE_DIR=${BASE_DIR:="${PWD}/.."}
echo "BASE_DIR set to $BASE_DIR"
export ISTIO_CONFIG_DIR="$BASE_DIR"

# Install Istio on ${CONTEXT}
kubectx ${CONTEXT}

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

# cd back into install/
cd ../

kubectl label namespace default istio-injection=enabled
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)

# install using operator config - https://istio.io/docs/setup/install/istioctl/#customizing-the-configuration
INSTALL_PROFILE="./istio_operator.yaml"
${WORK_DIR}/istioctl manifest apply -f ${INSTALL_PROFILE}

# redeploy the pods
cd ../release
kubectl delete -f kubernetes-manifests.yaml
kubectl apply -f kubernetes-manifests.yaml