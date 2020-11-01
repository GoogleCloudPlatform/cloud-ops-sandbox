#!/bin/bash
# 
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#--------------------------------------------------------------------------
# Environment variables:
# DBHOST - IP address of the Cloud SQL instance
# DBNAME - a name of the Postgres DB
# DBUSER - DB user
# DBPWD  - DB user password
#--------------------------------------------------------------------------

#
# authorize access to sql instance from local machine
# (machine has to have public ip)
#
MY_PUBLIC_IP=`dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}'`
gcloud sql instances patch $INSTANCE_NAME --authorized-networks=$MY_PUBLIC_IP --quiet

#
# create schema
#

echo "Creating table [ratings]..."
PGPASSWORD=$DBPWD psql -h $DBHOST -d $DBNAME -U $DBUSER -c "CREATE TABLE IF NOT EXISTS ratings (eid char(16),rating real,votes integer,PRIMARY KEY(eid));"
echo "Creating table [votes]..."
PGPASSWORD=$DBPWD psql -h $DBHOST -d $DBNAME -U $DBUSER -c "CREATE TABLE IF NOT EXISTS votes (id SERIAL,eid char(16),rating integer,in_process boolean DEFAULT FALSE,PRIMARY KEY(id));"
#
# populate schema
#
echo "Generating ratings..."
echo "eid,rating,votes" >> generated_data.csv
jq -r '.products[].id' ../src/productcatalogservice/products.json | while read line ; do echo "$line,$(( $RANDOM % 5 + 1)),$(( $RANDOM % 50 + 1))" >> generated_data.csv; done
echo "Populating ratings to DB..."
cat generated_data.csv | PGPASSWORD=$DBPWD psql -h $DBHOST -d $DBNAME -U $DBUSER -c "COPY ratings FROM STDIN DELIMITER ',' CSV HEADER;"
rm generated_data.csv

#
# remove authorized ips
#
gcloud sql instances patch $INSTANCE_NAME --clear-authorized-networks --quiet
