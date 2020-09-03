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
# python3 telemetry.py --session=$SESSION --project_id=$PROJECT_ID--event=$EVENT --version=$VERSION

# from google.cloud import pubsub_v1
from google.cloud import storage, exceptions
#from google.api_core import exceptions
from datetime import datetime
import sys
import json
import hashlib
import click

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

def get_telemetry_msg(session, project-id, event, version):
    datetime=get_datetime_str()
    project=get_id_hash(project-id)
    
    # send in json format
    data = {
        "session": session,
        "project": project,
        "event": event,
        "datetime": datetime,
        "version": version
    }
    msg = json.dumps(data)
    return msg

@click.command()
@click.option('--session', help='Current session (unique across projects).')
@click.option('--project-id', help='Project id in Google Cloud Platform.')
@click.option('--event', help='The  event that occurred.')
@click.option('--version', default="v0.2.5", help='Release version of Sandbox.')
def store_message(session, project-id, event, version):
    # send data as a bytestring
    msg = get_telemetry_msg(session, project-id, event, version)
    print("sending data", data)	
    data = data.encode("utf-8")
    
    # connect to pubsub and send message
    project_id = "stackdriver-sandbox-230822"
    topic_id = "telemetry"
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, topic_id)	topic_path = publisher.topic_path(project_id, topic_id)
    publisher.publish(topic_path, data=data)

if __name__ == "__main__":
    store_message()
