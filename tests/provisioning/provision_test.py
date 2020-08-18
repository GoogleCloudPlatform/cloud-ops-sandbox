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

from __future__ import print_function

import os
import unittest
import subprocess
from shlex import split
import json
import urllib.request

from google.cloud.container_v1.services import cluster_manager
from google.cloud.trace_v1 import trace_service_client
from google.cloud import error_reporting

class TestGKECluster(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        """ Get the location of GKE cluster for later queries """
        command = ('gcloud container clusters list --format="value(location)"')
        result = subprocess.run(split(command), encoding='utf-8', capture_output=True)
        cls.location = str(result.stdout.replace('\n', ''))
        if cls.location == '':
            raise Exception('GKE cluster is not provisioned!')
        cls.name = 'projects/' + getProjectId() + '/locations/' + cls.location + '/clusters/stackdriver-sandbox'
    
    def testNodeMachineType(self):
        """ Test if the machine type for the nodes is as specified """
        client = cluster_manager.ClusterManagerClient()
        cluster = client.get_cluster(name=self.__class__.name)
        node_config = cluster.node_config
        self.assertEqual(node_config.machine_type, 'n1-standard-2')

    def testNumberOfNode(self):
        """ Test if the number of nodes in the node pool is in the specified range """
        client = cluster_manager.ClusterManagerClient()
        cluster = client.get_cluster(name=self.__class__.name)
        self.assertTrue(cluster.current_node_count == 4)
    
    def testStatusOfServices(self):
        """ Test if all the service deployments are ready """
        command = ("kubectl get deployment --all-namespaces -o json")
        result = subprocess.run(split(command), encoding='utf-8', capture_output=True)
        services = json.loads(result.stdout)
        for service in services['items']:
            self.assertTrue(int(service['status']['readyReplicas']) >= 1)
    
    def testReachOfFrontend(self):
        """ Test if query frontend returns 200 """
        command_ip = ("kubectl get svc frontend-external -o json")
        result_ip = subprocess.run(split(command_ip), encoding='utf-8', capture_output=True)
        info = json.loads(result_ip.stdout)
        external_ip = info['status']['loadBalancer']['ingress'][0]['ip']
        port = info['spec']['ports'][0]['port']
        url = "".join(["http://", external_ip, ':', str(port)])
        self.assertTrue(urllib.request.urlopen(url).getcode() == 200)

class TestLoadGenerator(unittest.TestCase):
    def testReachOfLoadgen(self):
        """ Test if query load generator returns 200 """
        command_ip = ('gcloud compute instances list --filter="name:loadgenerator*" --format="value(networkInterfaces[0].accessConfigs.natIP)"')
        result_ip = subprocess.run(split(command_ip), encoding='utf-8', capture_output=True)
        url = "".join(['http://', result_ip.stdout.split('\n')[0], ':8080'])
        self.assertTrue(urllib.request.urlopen(url).getcode() == 200)

class TestProjectResources(unittest.TestCase):
    def testCloudTrace(self):
        """ Test if Cloud Trace is provisioned """
        try:
            command = ('gcloud alpha trace sinks list --project={0}'.format(getProjectId()))
            result = subprocess.run(split(command), encoding='utf-8', capture_output=True)
        except:
            self.fail("Trace not provisioned")
    
    def testCloudDebugger(self):
        """ Test if Cloud Debugger is provisioned """
        try:
            command = ('gcloud debug targets list')
            result = subprocess.run(split(command), encoding='utf-8', capture_output=True)
        except:
            self.fail("Debugger not provisioned")
    
    def testErrorReporting(self):
        """ Test if Error Reporting API is provisioned """
        client = error_reporting.Client(project=getProjectId())
        try:
            client.report("Testing reachability!")
        except:
            self.fail("Error reporting not provisioned")        

def getProjectId():
    """Retrieves the project id from the environment variable.
    Raises:
    Exception -- When not set.
    Returns:
    str -- the project name
    """
    project_id = os.environ['GOOGLE_CLOUD_PROJECT']

    if not project_id:
        raise Exception(
            'Set the environment variable ' +
            'GOOGLE_CLOUD_PROJECT to your Google Cloud Project Id.')
    return project_id

if __name__ == '__main__':
	unittest.main()