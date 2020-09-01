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

from google.cloud import pubsub_v1
from datetime import datetime
import sys
import json
import hashlib
import uuid

project_id = "stackdriver-sandbox-230822"
topic_id = "telemetry"

publisher = pubsub_v1.PublisherClient()
# The `topic_path` method creates a fully qualified identifier
# in the form `projects/{project_id}/topics/{topic_id}`
topic_path = publisher.topic_path(project_id, topic_id)

def get_uuid():
    return uuid.uuid4()

# define the following helper functions
def get_datetime_str():
    # send current date and time for end of installation script
    now = datetime.now()
    data = now.strftime("%m/%d/%Y %H:%M:%S")
    return data

def get_id_hash(project_id):
    m = hashlib.sha256()
    m.update(project_id.encode('utf-8'))
    hashed = m.hexdigest()
    print("hashed: ", hashed)
    print("id: ", project_id)
    return hashed

def send_message(session, project, event, datetime, version, debug=False):
    # send in json format
    data = {
        "session": session,
        "project": project,
        "event": event,
        "datetime": datetime,
        "version": version
    }
    data = json.dumps(data)
    if (debug): print(data)

    # Data must be a bytestring
    if (debug): print("sending data", data)
    data = data.encode("utf-8")

    # When you publish a message, the client returns a future.
    future = publisher.publish(topic_path, data=data)
    if (debug): print(future.result())

def main():
    # send messages
    # schema: session UUID, project UUID, event, date-time, version
    session=sys.argv[1]
    project=get_id_hash(sys.argv[2])
    event=sys.argv[3]
    datetime=get_datetime_str()
    version=sys.argv[4]
    send_message(session, project, event, datetime, version, debug=True)

if __name__ == "__main__":
    main()