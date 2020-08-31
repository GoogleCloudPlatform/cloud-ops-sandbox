from google.cloud import pubsub_v1
from datetime import datetime
import sys

project_id = "stackdriver-sandbox-230822"
topic_id = "telemetry"

publisher = pubsub_v1.PublisherClient()
# The `topic_path` method creates a fully qualified identifier
# in the form `projects/{project_id}/topics/{topic_id}`
topic_path = publisher.topic_path(project_id, topic_id)

# define the following helper functions
def get_datetime_str():
    # send current date and time for end of installation script
    now = datetime.now()
    data = now.strftime("%m/%d/%Y %H:%M:%S")
    return data

def send_message(args, debug=False):
    # send in json format
    data = "{\n\"date\":\"" + get_datetime_str() + "\","
    
    # First arg in args is name of script, 'telemetry.py', so we skip it
    for i in range(len(args) - 1):
        key_value = args[i + 1].split("=")
        data += "\n\"" + key_value[0] + "\":\"" + key_value[1]  + "\""
    data += "\n}"

    # Data must be a bytestring
    if (debug): print("sending data", data)
    data = data.encode("utf-8")

    # When you publish a message, the client returns a future.
    future = publisher.publish(topic_path, data=data)
    if (debug): print(future.result())

# send messages
send_message(sys.argv)
