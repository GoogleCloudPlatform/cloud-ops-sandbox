#!/bin/bash
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

set -x
set +e

# This script is responsible for deleting resources out of a
# Cloud Operations Sandbox project in between test runs

export PROJECT_ID=$(gcloud config get-value project)
export WORKDIR=$(dirname $(realpath $0))

# clear monitoring
python3 -m pip install -r ${WORKDIR}/requirements.txt
python3 ${WORKDIR}/cleanup_monitoring.py "projects/$PROJECT_ID"

# delete service account
CLUSTER_ZONE="first_run"
while [ -n "$CLUSTER_ZONE" ]; do
  GSA_EMAIL=$(gcloud iam service-accounts list \
                    --filter="name:gke-sa" \
                    --project $PROJECT_ID --format="value(email)")
  if [ -n "$GSA_EMAIL" ]; then
      echo "deleting service account"
      gcloud iam service-accounts delete $GSA_EMAIL
      sleep 20
  fi
done

# delete cluster
CLUSTER_ZONE="first_run"
while [ -n "$CLUSTER_ZONE" ]; do
  CLUSTER_ZONE=$(gcloud container clusters list \
                   --filter="name:cloud-ops-sandbox" \
                   --project $PROJECT_ID --format="value(zone)")
  if [ -n "$CLUSTER_ZONE" ]; then
      echo "deleting cluster"
      gcloud container clusters delete cloud-ops-sandbox \
          --project $PROJECT_ID --zone $CLUSTER_ZONE --quiet
      sleep 20
  fi
done

# delete GKE loadgenerator
LOADGENERATOR_ZONE="first_run"
while [ -n "$LOADGENERATOR_ZONE" ]; do
  LOADGENERATOR_ZONE=$(gcloud container clusters list \
                   --filter="name:loadgenerator" \
                   --project $PROJECT_ID --format="value(zone)")
  if [ -n "$LOADGENERATOR_ZONE" ]; then
      echo "deleting load generator cluster"
      gcloud container clusters delete loadgenerator \
          --project $PROJECT_ID --zone $LOADGENERATOR_ZONE --quiet
      sleep 20
  fi
done

# delete legacy GCE loadgenerator
LOADGENERATOR="first_run"
while [ -n "$LOADGENERATOR" ]; do
  read -r LOADGENERATOR ZONE <<< $(gcloud compute instances list \
                                    --filter="name:loadgenerator*" \
                                    --project $PROJECT_ID --format="value(name, zone)")
  if [ -n "$LOADGENERATOR" ]; then
      echo "deleting loadgenerator"
      gcloud compute instances delete $LOADGENERATOR \
          --project $PROJECT_ID --zone $ZONE --quiet
      sleep 5
  fi
done

# clear bucket
BUCKET_CONTENTS="first_run"
while [ -n "$BUCKET_CONTENTS" ]; do
  BUCKET_CONTENTS=$(gsutil ls gs://$PROJECT_ID-bucket)
  if [ -n "$BUCKET_CONTENTS" ]; then
      echo "deleting bucket data"
      gsutil rm -r "gs://$PROJECT_ID-bucket/**"
      sleep 5
  fi
done

# clear logs
for LOG in $(gcloud logging logs list --project $PROJECT_ID --format="value(NAME)"); do
    echo "deleting $LOG..."
    gcloud logging logs delete $LOG --project $PROJECT_ID --quiet
done
