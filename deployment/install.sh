#!/bin/bash
#
# Create a new deployment of Hipster Shop

# Install Prerequisites
#sudo apt-get install jshon

PROJECT_NAME="sandbox-demos"
ORGANIZATION_ID=396521612403
FOLDER_ID=396521612403
ZONE="us-west1-a"
CLUSTER_NAME=hipstershop
SERVICE_ACCOUNT_NAME=hipstershop-service-account

if [ "$#" -lt 3 ]; then
   echo "Usage:  ./install.sh billingid project-prefix  email"
   echo "   eg:  ./install.sh 0X0X0X-0X0X0X-0X0X0X sandbox-20190106 somebody@gmail.com"
   exit
fi

ACCOUNT_ID=$1
shift
PROJECT_PREFIX=$1
shift
EMAILS=$@

# Update gcloud SDK
#gcloud components update

# The following might be needed for Stackdriver Workspaces API
# gcloud components install alpha

for EMAIL in $EMAILS; do
   PROJECT_ID=$(echo "${PROJECT_PREFIX}-${EMAIL}" | sed 's/@/x/g' | sed 's/\./x/g' | cut -c 1-30)
   gcloud services enable container.googleapis.com --project $PROJECT_ID
   echo "Creating project $PROJECT_NAME for $EMAIL ... "

   # create
   gcloud projects create $PROJECT_ID --name $PROJECT_NAME --enable-cloud-apis --labels=product=sandbox --folder=$FOLDER_ID
   #--organization=$ORGANIZATION_ID
   sleep 2

   # editor
   rm -f iam.json.*
   gcloud projects get-iam-policy $PROJECT_ID --format=json > iam.json.orig
   cat iam.json.orig | sed s'/"bindings": \[/"bindings": \[ \{"members": \["user:'$EMAIL'"\],"role": "roles\/editor"\},/g' > iam.json.new
   gcloud projects set-iam-policy $PROJECT_ID iam.json.new

   # billing
   gcloud beta billing projects link $PROJECT_ID --billing-account=$ACCOUNT_ID

done

#################
# Create service account for project 
gcloud iam service-accounts create hipstershop-service-account --display-name="Hipstershop Service Account" --project $PROJECT_ID

# List service accounts and assign full address to IAM_ACCOUNT variable
gcloud iam service-accounts list --project $PROJECT_ID

# alternative: append project and iam.gserviceacccount.com suffix
#$IAM_ACCOUNT={$SERVICE_ACCOUNT_NAME}@{$PROJECT_NAME}.iam.gserviceaccount.com
IAM_ACCOUNT=$(gcloud iam service-accounts list --project $PROJECT_ID --format="value(email)")

# Add service account to be an owner of the project
gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$IAM_ACCOUNT --role roles/owner

# Create private key for service account
gcloud iam service-accounts keys create hipstershop_credentials.json --iam-account=$IAM_ACCOUNT --key-file-type=json --project $PROJECT_ID

# Activate authentication with service account
gcloud auth activate-service-account $IAM_ACCOUNT --key-file=hipstershop_credentials.json --project $PROJECT_ID

# Enable APIs
# List all available to find the right command for missing API
# gcloud services list --available
gcloud services enable container.googleapis.com --project $PROJECT_ID
gcloud services enable cloudtrace.googleapis.com --project $PROJECT_ID

# Create GKE cluster
gcloud container clusters create $CLUSTER_NAME --enable-autoupgrade --enable-autoscaling --min-nodes=3 --max-nodes=10 --num-nodes=5 --zone=$ZONE --labels=product=hipstershop --node-labels=product=hipstershop --scopes=cloud-platform --project $PROJECT_ID

# Enable Google Container Registry
gcloud services enable containerregistry.googleapis.com --project $PROJECT_ID

# Add GCR authentication support to docker
gcloud auth configure-docker -q --project $PROJECT_ID

# Get Skaffold
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
chmod +x skaffold
sudo mv skaffold /usr/local/bin

# build everything locally and push to gcr, then deploy to gke
skaffold run --default-repo=gcr.io/$PROJECT_ID

# get external IP
kubectl service frontend-external