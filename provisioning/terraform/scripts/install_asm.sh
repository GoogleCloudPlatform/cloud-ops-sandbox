#!/bin/bash
# Copyright 2023 Google LLC
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

WORK_DIR=$(realpath $(dirname "$0"))
pushd "$WORK_DIR" > /dev/null

SCRIPT_NAME="${0##*/}"; readonly SCRIPT_NAME
ASM_VERSION=1.16; readonly ASM_VERSION

info() {
  echo "⚙️  ${SCRIPT_NAME}: ${1}" >&2
}

x_usage() {
  cat << EOF
${SCRIPT_NAME}
usage: ${SCRIPT_NAME} [PARAMETER]...

Configures managed Anthos Service Mesh (ASM) on the GKE cluster.

PARAMETERS:
  --channel                           (Optional) Managed ASM revision
                                      channel. Should be one of the following:
                                      'stable', 'rapid' or 'regular'.
                                      Default is 'stable'.
  --cluster_location                  Zone or region name where the cluster
                                      is provisioned.
  --cluster_name                      The name of GKE cluster.
                                      allow external VM workloads.
  --project                           Google Cloud Project ID that
                                      hosts the cluster.
EOF
}

fatal() {
  error "${1}"
  exit 2
}

arg_required() {
  if [[ ! "${2:-}" || "${2:0:1}" = '-' ]]; then
    fatal "Option ${1} requires an argument."
  fi
}

parse_args() {
  while [[ $# != 0 ]]; do
    case "${1}" in
      --project)
        arg_required "${@}"
        PROJECT_ID="${2}"
        shift 2
        ;;
      --channel)
        arg_required "${@}"
        CHANNEL="${2}"
        shift 2
        ;;
      --cluster_name)
        arg_required "${@}"
        CLUSTER_NAME="${2}"
        shift 2
        ;;
      --cluster_location)
        arg_required "${@}"
        CLUSTER_LOCATION="${2}"
        shift 2
        ;;
      -h | --help)
        x_usage
        exit
        ;;
      *)
        x_usage
        break
        ;;
    esac
  done

  if [[ -z ${PROJECT_ID} ]] || [[ -z ${CLUSTER_NAME} ]] || [[ -z ${CLUSTER_LOCATION} ]]; then
    info "Need to define project id, GKE cluster name and location"
    exit 2
  fi
  if [[ "${CHANNEL}" != "stable" && "${CHANNEL}" != "regular" && "${CHANNEL}" != "rapid" ]]; then
    if [[ -n "${CHANNEL}" ]]; then
      info "Valid channel is not found. 'stable' channel will be used."
    fi
    CHANNEL="stable"
  fi
}

parse_args "$@"

info "Downloading asmcli version ${ASM_VERSION}"
curl -s https://storage.googleapis.com/csm-artifacts/asm/asmcli_${ASM_VERSION} > asmcli
chmod -f +x asmcli

info "Installing managed ASM version ${ASM_VERSION} for GKE cluster ${CLUSTER_NAME} ..."

./asmcli install \
  --project_id $PROJECT_ID \
  --cluster_name ${CLUSTER_NAME} \
  --cluster_location ${CLUSTER_LOCATION} \
  --fleet_id ${PROJECT_ID} \
  --enable_all \
  --option prometheus-and-stackdriver \
  --managed \
  --channel ${CHANNEL} \
  --use_managed_cni

info "Annotating default namespaces for istio injection ..."
kubectl label namespace default istio-injection- istio.io/rev=asm-managed-${CHANNEL} --overwrite

# clean up
rm ./asmcli

popd
