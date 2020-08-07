#!/bin/bash
set -ex

export PROJECT_ID=$(gcloud config get-value project)

check_resource() {
    if [ ! -z "$2" ]; then
        echo "found $1"
        echo $2
        exit 1
    fi
}

CLUSTERS=$(gcloud container clusters list --project $PROJECT_ID --format="value(name)")
check_resource "cluster" $CLUSTERS

GCE_INSTANCES=$(gcloud compute instances list --project $PROJECT_ID \
                  --format="value(name)" --filter="name:loadgenerator*")
check_resource "instance" $GCE_INSTANCES

BUCKET_CONTENTS=$(gsutil ls gs://$PROJECT_ID-bucket)
check_resource "bucket contents" $BUCKET_CONTENTS

#DASHBOARDS=$(gcloud monitoring dashboards list --project $PROJECT_ID --format="value(name)")
#check_resource "dashboard" $DASHBOARDS

#LOGS=$(gcloud logging logs list --project $PROJECT_ID --format="value(NAME)")
#echo $LOGS
