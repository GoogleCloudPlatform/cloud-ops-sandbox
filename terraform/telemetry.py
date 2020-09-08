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
# python3 telemetry.py --session=$SESSION --project_id=$PROJECT_ID --event=$EVENT --version=$VERSION

import sys
import json
import hashlib
import click
import time
import re

from google.cloud import pubsub_v1

# This function hashes the project_id in order to preserve user privacy
# The telemetry system should not have access to the user's actual project_id
def obfuscate_project_id(project_id):
    m = hashlib.sha256()
    m.update(project_id.encode('utf-8'))
    hashed = m.hexdigest()
    return hashed

# formats JSON object and re-forms project argument
def get_telemetry_msg(session, project_id, event, version):
    datetime=time.time() # Unix timestamp
    project=obfuscate_project_id(project_id)
    
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

# returns True if arguments are valid (correct format and type)
# returns False along with an error message if not
def validate_args(session, project_id, event, version):
    args_exp = {
        "version": r"^v\d.\d.\d$",
        "project_id": r"^cloud-ops-sandbox-(\d){9}$",
        "v4uuid": r"^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}$"
    }
    
    # check types
    if (not isinstance(event, str) or not isinstance(version, str) or
        not isinstance(project_id, str) or not isinstance(session, str)):
        return False, "An argument passed to telemetry was an invalid type."
    
    # check format
    if (re.fullmatch(args_exp["version"], version) is None or
        re.fullmatch(args_exp["project_id"], project_id) is None or
        re.fullmatch(args_exp["session"], session) is None):
        return False, "An argument passed to telemetry was an invalid format."
    
    return True, ""

@click.command()
@click.option('--session', help='Current session (unique across projects).')
@click.option('--project_id', help='Sandbox project id in Google Cloud Platform.')
@click.option('--event', help='The  event that occurred.')
@click.option('--version', help='Release version of Sandbox.')
def send_telemetry_message(session, project_id, event, version):
    # validate data
    valid, err_msg = validate_args(session, project_id, event, version)
    if (not valid):
        print("Failed to send telemetry.")
        print(err_msg)
        return
    
    # send data as a bytestring
    msg = get_telemetry_msg(session, project_id, event, version)
    bytes = msg.encode("utf-8")
    
    # connect to pubsub and send message
    project_id = "stackdriver-sandbox-230822"
    topic_id = "telemetry"
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, topic_id)
    
    publisher.publish(topic_path, data=bytes)

if __name__ == "__main__":
    send_telemetry_message()
