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
import time
import concurrent.futures

from google.cloud import monitoring_v3


def getIstioServiceName(service_name, project_id, zone):
    """ Returns the Istio service name of a certain service. """
    return "ist:{}-zone-{}-cloud-ops-sandbox-default-{}".format(project_id, zone, service_name)


def findService(client, service_name, project_id, zone, should_timeout):
        """ Checks to see if a service exists in Cloud Monitoring 
        Arguments:
        client - the API client
        service_name - the Istio service name, returned from getIstioServiceName
        project_id - the Sandbox project id
        zone - the zone of the Sandbox cluster
        should_timeout - whether to timeout after 5 minutes or wait indefinitely for the service
        """
        found_service = False
        full_service_name = getIstioServiceName(service_name, project_id, zone)
        service = client.service_path(project_id, full_service_name)
        num_tries = 0
        while not found_service and num_tries <= 50:
            try:
                found_service = client.get_service(name=service)
            except: # possible exceptions include GoogleAPICallError and ValueError
                if should_timeout:
                    num_tries += 1
                time.sleep(6)
                found_service = False


def waitForIstioServicesDetection(project_id, zone, should_timeout):
    """ Waits for Istio services to be detected in Cloud Monitoring as a prerequisite for Terraform monitoring provisioning
    Arguments:
    project_id - the Sandbox project id (cloud-ops-sandbox-###)
    zone - the zone of the Sandbox cluster
    should_timeout - whether to timeout after 1 minute or wait indefinitely for the service
    """
    client = monitoring_v3.ServiceMonitoringServiceClient()

    # wait for each Istio service to be detected by Cloud Monitoring
    services = ["cartservice", "productcatalogservice", "currencyservice", "recommendationservice",
                "adservice", "frontend", "checkoutservice", "paymentservice", "emailservice", "shippingservice"]
    with concurrent.futures.ThreadPoolExecutor(max_workers=len(services)) as executor:
        for service in services:
            executor.submit(findService, client, service,
                            project_id, zone, should_timeout)


if __name__ == '__main__':
    project_id = ''
    zone = ''
    try:
        project_id = sys.argv[1]
        zone = sys.argv[2]
    except IndexError:
        exit('Missing Project Name or Zone. Usage: python3 istio_service_setup.py $project_id $zone')

    # optional parameter to determine whether we should timeout, default = True
    if len(sys.argv) == 4:
        should_timeout = False
    else:
        should_timeout = True
    waitForIstioServicesDetection(project_id, zone, should_timeout)
