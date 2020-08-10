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
# stackdriver sandbox project in between test runs

export PROJECT_ID=$(gcloud config get-value project)

# delete cluster
CLUSTER_ZONE="first_run"
while [ -n "$CLUSTER_ZONE" ]; do
  CLUSTER_ZONE=$(gcloud container clusters list \
                   --filter="name:stackdriver-sandbox" \
                   --project $PROJECT_ID --format="value(zone)")
  if [ -n "$CLUSTER_ZONE" ]; then
      echo "deleting cluster"
      gcloud container clusters delete stackdriver-sandbox \
          --project $PROJECT_ID --zone $CLUSTER_ZONE --quiet
      sleep 20
  fi
done


# delete loadgenerator
LOADGENRATOR="first_run"
while [ -n "$LOADGENRATOR" ]; do
  read -r LOADGENRATOR ZONE <<< $(gcloud compute instances list \
                                    --filter="name:loadgenerator*" \
                                    --project $PROJECT_ID --format="value(name, zone)")
  if [ -n "$LOADGENRATOR" ]; then
      echo "deleting loadgenerator"
      gcloud compute instances delete $LOADGENRATOR \
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

# clear dashboards
DASHBOARD_LIST="first_run"
while [ -n "$DASHBOARD_LIST" ]; do
  DASHBOARD_LIST=$(gcloud monitoring dashboards list --format="value(name)")
  if [ -n "$DASHBOARD_LIST" ]; then
    for DASHBOARD in $DASHBOARD_LIST; do
      gcloud monitoring dashboards delete $DASHBOARD --quiet
    done
  fi
done

# clear policies
POLICY_LIST="first_run"
while [ -n "$POLICY_LIST" ]; do
  POLICY_LIST=$(gcloud alpha monitoring policies list --format="value(name)")
  if [ -n "$POLICY_LIST" ]; then
    for POLICY in $POLICY_LIST; do
      gcloud alpha monitoring policies delete $POLICY --quiet
    done
  fi
done

# clear notification channels
CHANNEL_LIST="first_run"
while [ -n "$CHANNEL_LIST" ]; do
  CHANNEL_LIST=$(gcloud alpha monitoring channels list --format="value(name)")
  if [ -n "$CHANNEL_LIST" ]; then
    for CHANNEL in $CHANNEL_LIST; do
      gcloud alpha monitoring channels delete $CHANNEL --quiet
    done
  fi
done
