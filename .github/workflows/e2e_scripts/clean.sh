#!/bin/bash
set -x

export PROJECT_ID=stackdriver-sandbox-e2e

# delete cluster
CLUSTER_ZONE=$(gcloud container clusters list \
                 --filter="name:stackdriver-sandbox" \
                 --project $PROJECT_ID --format="value(zone)")
if [ ! -z "$CLUSTER_ZONE" ]; then
    echo "deleting cluster"
    gcloud container clusters delete stackdriver-sandbox \
        --project $PROJECT_ID --zone $CLUSTER_ZONE --quiet
fi

# delete loadgenerator
read -r LOADGENRATOR ZONE <<< $(gcloud compute instances list \
                                  --filter="name:loadgenerator*" \
                                  --project $PROJECT_ID --format="value(name, zone)")
if [ ! -z "$LOADGENRATOR" ]; then
    echo "deleting loadgenerator"
    gcloud compute instances delete $LOADGENRATOR \
        --project $PROJECT_ID --zone $ZONE --quiet
fi

# clear bucket
BUCKET_CONTENTS=$(gsutil ls gs://$PROJECT_ID-bucket)
if [ ! -z "$BUCKET_CONTENTS" ]; then
    echo "deleting bucket data"
    gsutil rm -r "gs://$PROJECT_ID-bucket/**"
fi

# clear logs
for LOG in $(gcloud logging logs list --project $PROJECT_ID --format="value(NAME)"); do
    echo "deleting $LOG..."
    gcloud logging logs delete $LOG --project $PROJECT_ID --quiet | true
done

