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
python3 -m pip install --user -r ${WORKDIR}/requirements.txt
python3 ${WORKDIR}/cleanup_monitoring.py "projects/$PROJECT_ID"

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
AUDIT_LOG_SUFFIX="logs/cloudaudit.googleapis.com"
for LOG in $(gcloud logging logs list --project $PROJECT_ID --format="value(NAME)"); do
    if [[ ! $LOG =~ $AUDIT_LOG_SUFFIX ]]; then
      echo "deleting $LOG...";
      gcloud logging logs delete $LOG --project $PROJECT_ID --quiet;
    fi
done

# delete scheduler job
echo "deleting scheduler job 'ratingservice-recollect-job'..."
gcloud scheduler jobs describe ratingservice-recollect-job --project=$PROJECT_ID 2>/dev/null
[ $? -eq 0 ] && gcloud scheduler jobs delete ratingservice-recollect-job --project=$PROJECT_ID --quiet

# delete app engine "ratingservice" service (default service cannot be deleted)
echo "deleting App Engine service 'ratingservice'..."
gcloud app services describe ratingservice --project=$PROJECT_ID 2>/dev/null
[ $? -eq 0 ] && gcloud app services delete ratingservice --project=$PROJECT_ID --quiet

# delete rating service code buckets
for BUCKET_NAME in $(gsutil ls -p $PROJECT_ID | grep ratingservice-deployables-); do
  echo "deleting $BUCKET_NAME..."
  gsutil rm -r $BUCKET_NAME
done

# delete Cloud SQL instances
for INSTANCE_NAME in $(gcloud sql instances list --project=$PROJECT_ID --format="value(NAME)"); do
  echo "deleting Cloud SQL instance $INSTANCE_NAME..."
  gcloud sql instances delete $INSTANCE_NAME --project=$PROJECT_ID --quiet
done

# delete GKE hub clusters
for CLUSTER_NAME in $(gcloud container fleet memberships list --format="value(NAME)"); do
  echo "deleting GKE hub membership $CLUSTER_NAME"
  gcloud container fleet memberships delete $CLUSTER_NAME
done
