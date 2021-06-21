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
# DB_HOST       - Cloud SQL instance connection name
# DB_NAME       - Postgres DB name
# DB_USERNAME   - DB user name
# DB_PASSWORD   - DB user password
#--------------------------------------------------------------------------

project_id=$1
#
# open SQL proxy session to connect to CloudSQL instance
#
echo "Launching Cloud SQL Proxy in background..."
cloud_sql_proxy -instances=$DB_HOST=tcp:5432 -verbose=false &>/dev/null &
cloud_proxy_pid=$!

# wait until proxy connects or 5 attempts fail
tries=0
while [[ "${tries}" -lt 5 ]]; do
    echo "Waiting for establishing connection to db..."
    status_str=$(PGPASSWORD=$DB_PASSWORD psql "host=127.0.0.1 sslmode=disable dbname=$DB_NAME user=$DB_USERNAME" -q -c '\conninfo' 2>/dev/null)
    if [[ -n "$status_str" ]]; then
        echo "Connection established"
        break
    else
        sleep 2
        tries=$((tries + 1))
    fi
done

#
# configure db schema and populate rating entities
#
echo "Creating table [ratings]..."
PGPASSWORD=$DB_PASSWORD psql "host=127.0.0.1 sslmode=disable dbname=$DB_NAME user=$DB_USERNAME" <<EOF
CREATE TABLE IF NOT EXISTS ratings(
    eid char(16),
    rating numeric,
    votes integer,
    PRIMARY KEY(eid)
);
CREATE TABLE IF NOT EXISTS votes(
    id SERIAL,
    eid char(16),
    rating integer,
    in_process boolean DEFAULT FALSE,
    PRIMARY KEY(id),
    CONSTRAINT FK_votes_to_ratings
        FOREIGN KEY (eid)
            REFERENCES ratings(eid) 
);
CREATE INDEX IF NOT EXISTS INDX_votes_eid ON votes (eid);
EOF

#
# populate all products' ratings with random integers in [1..5] per single vote
#
echo "Generating ratings..."
echo "eid,rating,votes" >> generated_data.csv
jq -r '.products[].id' ../src/productcatalogservice/products.json | while read line ; do echo "$line,$(( $RANDOM % 5 + 1)),1" >> generated_data.csv; done
echo "Populating ratings to DB..."
cat generated_data.csv | PGPASSWORD=$DB_PASSWORD psql "host=127.0.0.1 sslmode=disable dbname=$DB_NAME user=$DB_USERNAME" -c "COPY ratings FROM STDIN DELIMITER ',' CSV HEADER;"
rm generated_data.csv

#
# close SQL proxy session
#
kill $cloud_proxy_pid; wait $cloud_proxy_pid 2>/dev/null
echo "Cloud SQL Proxy background process is killed."
