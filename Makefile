# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

.-PHONY: cluster deploy deploy-continuous logs check-env check-service

ZONE=us-west1-a
CLUSTER=cloud-ops-sandbox-${USER}

cluster: check-env
	gcloud services enable container.googleapis.com
	EXISTING_CLUSTER=`gcloud container clusters list --zone=${ZONE} --format="value(name)" --filter="name:${CLUSTER}"`
	if [ "${EXISTING_CLUSTER}" != "" ]; then \
    	gcloud container clusters delete ${CLUSTER} --project=${PROJECT_ID} --zone=${ZONE} --quiet; \
	fi

	gcloud beta container clusters create ${CLUSTER} \
		--project=${PROJECT_ID} --zone=${ZONE} \
		--machine-type=n1-standard-2 --num-nodes=2 \
		--enable-stackdriver-kubernetes \
		--scopes https://www.googleapis.com/auth/cloud-platform
	cd ./terraform/istio && \
	./install_istio.sh
	skaffold run --default-repo=gcr.io/${PROJECT_ID}/sandbox -l skaffold.dev/run-id=${CLUSTER}-${PROJECT_ID}-${ZONE}
	kubectl set env deployment.apps/frontend RATING_SERVICE_ADDR=http://some.host

deploy: check-env
	echo ${CLUSTER}
	gcloud container clusters get-credentials --project ${PROJECT_ID} ${CLUSTER} --zone ${ZONE}
	skaffold run --default-repo=gcr.io/${PROJECT_ID}/sandbox -l skaffold.dev/run-id=${CLUSTER}-${PROJECT_ID}-${ZONE} --status-check=false
	kubectl set env deployment.apps/frontend RATING_SERVICE_ADDR=http://some.host

deploy-continuous: check-env
	gcloud container clusters get-credentials --project ${PROJECT_ID} ${CLUSTER} --zone ${ZONE}
	skaffold dev --default-repo=gcr.io/${PROJECT_ID}/sandbox --status-check=false

logs: check-service
	kubectl logs deployment/${SERVICE}

check-env:
ifndef PROJECT_ID
	$(error PROJECT_ID is undefined)
endif

ifndef ZONE
	$(error ZONE is undefined)
endif

check-service:
ifndef SERVICE
	$(error SERVICE is undefined. Enter a service name (e.g. SERVICE=frontend))
endif
