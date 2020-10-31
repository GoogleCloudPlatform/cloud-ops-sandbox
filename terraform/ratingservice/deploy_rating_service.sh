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

#--------------------------------------------------------------------------
# Environment variables:
# REGION - defines GCP region where application has to be deployed
# VERSION - a version of the application to be deployed
# DB_HOST - IP address of the Cloud SQL instance
# DB_NAME - a name of the Postgres DB
# DB_USER - DB user
# DB_PWD - DB user password
#--------------------------------------------------------------------------
REGION=${REGION:-us-east1}
VERSION=${VERSION:-prod}

#
# check if need to create GAE application
#
gcloud describe &> /dev/null
if [ $? -ne 0 ]; then
    gcloud app create --region=$REGION
fi

#
# deploy rating service to GAE
#
pushd
cd ../src/ratingservice
sed "s/\${DBHOST}/$DBHOST/;s/\${DBNAME}/$DBNAME/;s/\${DBUSER}/$DBUSER/;s/\${DBPWD}/$DBPWD/;" app.template > app.yaml 
gcloud app deploy --version=$VERSION --quiet
rm app.yaml
popd
