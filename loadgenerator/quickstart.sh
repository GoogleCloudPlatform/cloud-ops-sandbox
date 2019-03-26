#!/bin/bash
# quickstart.sh
# Starts user load generation for a given Stackdriver Sandbox application
#
# Creates and configures a load generation job on Compute Engine.
# Automatically starts sending requests to a given frontend address of a
# running Stackdriver Sandbox application.
#
# Suggested usage:
#   kubectl get service frontend-external
#   quickstart.sh $EXTERNAL-IP
#


set -e
trap "exit" TERM

ZONE="us-central1-c"
TIMEOUT=40
USER_COUNT=100

usage () {
    echo "Usage: $0 [TARGET_ADDRESS]"
    echo ""
    echo "$0 - Starts generating load for a Stackdriver Sandbox application."
    echo "[TARGET_ADDRESS] - The web address of the application to generate load for."
}

die () {
    echo >&2 "$@"
    echo ""
    usage
    exit 1
}

timeout () {
    local address=$1
    echo "ERROR: Timed out waiting for load generator job"
    echo "You can manually start the job by navigating to $address"
    exit 1
}

[ "$#" -eq 1 ] || die "Missing argument: [TARGET_ADDRESS]"
curl -f --max-time 5 $1 > /dev/null 2>&1 || die "Unable to connect to provided TARGET_ADDRESS: $1"
TARGET_ADDRESS=$1

echo "Setting up the load generation infrastructure..."
./loadgenerator-tool setup > /dev/null

echo "Creating a load generator to send load to $TARGET_ADDRESS..."
output=$(./loadgenerator-tool create $TARGET_ADDRESS --zone $ZONE)
job_address=${output##* }

echo "Waiting up to $TIMEOUT seconds for load generator to finish setting up..."
let retries=$TIMEOUT/5
curl -f -s -S --max-time 5 --retry $retries --retry-delay 5 --retry-max-time $TIMEOUT --retry-connrefused -X POST -F locust_count=$USER_COUNT -F hatch_rate=$USER_COUNT $job_address/swarm || timeout $job_address

# Connected successfully
echo "Automatically started load generation with $USER_COUNT users..."
echo "You can access the job by navigating to $job_address"

