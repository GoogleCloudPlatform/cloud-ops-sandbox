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


# File usage:
# python3 telemetry.py session project event version

# from google.cloud import pubsub_v1
from google.cloud import storage, exceptions
#from google.api_core import exceptions
from datetime import datetime
import sys
import json
import hashlib
import uuid
import click

def get_uuid():
    return uuid.uuid4()

# define the following helper functions
def get_datetime_str():
    # send current date and time for end of installation script
    now = datetime.utcnow()
    data = now.strftime("%m/%d/%Y %H:%M:%S")
    return data

def get_id_hash(project_id):
    m = hashlib.sha256()
    m.update(project_id.encode('utf-8'))
    hashed = m.hexdigest()
    return hashed

def get_telemetry_msg(session, project_id, event, version):
    datetime=get_datetime_str()
    project=get_id_hash(project_id)
    
    # send in json format
    data = {
        "session": session,
        "project": project,
        "event": event,
        "datetime": datetime,
        "version": version
    }
    msg = json.dumps(data)
    # file name should be descriptive but unique
    file_name = 'telemetry-' + project_id + "-" + str(get_uuid())
    return msg, file_name

@click.command()
@click.option('--session', help='Current session (unique across projects).')
@click.option('--bucket_name', help='Name of the bucket provisioned in user project for telemetry storage')
@click.option('--project_id', help='Project name in Google Cloud Platform.')
@click.option('--event', help='The  event that occurred.')
@click.option('--version', default="v0.2.5", help='Release version of Sandbox.')
def store_message(session, bucket_name, project_id, event, version):
    msg, file_name = get_telemetry_msg(session, project_id, event, version)
    
    # create bucket if none created yet
    storage_client = storage.Client()
    bucket = None
    try:
        bucket = storage_client.get_bucket(bucket_name)
    except exceptions.NotFound:
        bucket = storage_client.create_bucket(bucket_name)
        print("Bucket {} created.".format(bucket_name))
        
    blob = bucket.blob(file_name)
    print(blob)
    blob.upload_from_string(msg)

    print(
        "File {} uploaded to {}.".format(
            file_name, file_name
        )
    )
    

if __name__ == "__main__":
    store_message()
