#!/bin/bash

set -xe

function cleanup()
{
    docker stop test-runner
    docker rm test-runner
}
trap cleanup EXIT

docker create \
    --env GOOGLE_APPLICATION_CREDENTIALS=/service-account.json --env billing_acct="Cloud-DPE Billing Account" --env billing_id="01736B-39A020-40AF34" \
    --env SERVICE_ACCOUNT=$(cat service-account.json)
    --name test-runner \
    gcr.io/cloudshell-images/cloudshell@sha256:07cd187a2a26d2952b68ff9e4ac8d4cda9691fa1b5f7c7287f795f9d20005638

#docker cp ./service-account.json test-runner:/
#docker cp <(cat service-account.json) test-runner:/service-account.json
docker cp ./stackdriver-sandbox test-runner:/sandbox

docker start test-runner
docker exec test-runner /bin/bash -c "echo $SA > service-account.json"

#docker exec test-runner gcloud auth activate-service-account --key-file /service-account.json
#docker exec test-runner git clone -b install-tests https://github.com/Daniel-Sanche/stackdriver-sandbox.git sandbox
#docker exec test-runner /bin/bash ./sandbox/terraform/install.sh
docker exec test-runner /bin/cat /service-account.json

echo done

