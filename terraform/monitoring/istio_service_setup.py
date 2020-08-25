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

import os
import sys

from google.cloud import monitoring_v3

def getIstioServiceName(service_name, project_id, zone):
	return 'ist:' + project_id + '-zone-' + zone + '-stackdriver-sandbox-default-' + service_name

def findService(client, service_name, project_id, zone):
	found_service = False
	full_service_name = getIstioServiceName(service_name, project_id, zone)
	service = client.service_path(project_id, full_service_name)
	while not found_service:
		try:
			found_service = client.get_service(service)
		except:
			found_service = False
	print("Found " + service_name)

def waitForIstioServices(project_id, zone):
	client = monitoring_v3.ServiceMonitoringServiceClient()
	# wait for cart service
	findService(client, "cartservice", project_id, zone)

	# wait for product catalog service
	findService(client, "productcatalogservice", project_id, zone)

	# wait for currency service
	findService(client, "currencyservice", project_id, zone)

	# wait for recommendation service
	findService(client, "recommendationservice", project_id, zone)

	# wait for ad service
	findService(client, "adservice", project_id, zone)


if __name__ == '__main__':
    project_id = ''
    zone = ''
    try:
        project_id = sys.argv[1]
        zone = sys.argv[2]
    except:
        exit('Missing Project Name. Usage: python3 istio_service_setup.py $project_id $zone')
    waitForIstioServices(project_id, zone)