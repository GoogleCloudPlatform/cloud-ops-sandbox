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
from google.cloud import error_reporting
from google.api_core import exceptions

class TestGKECluster(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        """ Get the location of GKE cluster for later queries """
        cls.name = 'projects/{0}/locations/{1}/clusters/cloud-ops-sandbox'.format(getProjectId(), getClusterZone())
        # authenticate container cluster
        command=('gcloud config set project {0}'.format(getProjectId()))
        subprocess.run(split(command))
        # set kubectl context
        command=('gcloud container clusters get-credentials cloud-ops-sandbox --zone {0}'.format(getClusterZone()))
        subprocess.run(split(command))
        # obtain the context name
        command=('kubectl config current-context')
        result = subprocess.run(split(command), encoding='utf-8', capture_output=True)
        cls.context = result.stdout

    def testNodeMachineType(self):
        """ Test if the machine type for the nodes is as specified """
        client = cluster_manager.ClusterManagerClient()
        cluster_info = client.get_cluster(name=TestGKECluster.name)
        machine_type = cluster_info.node_config.machine_type
        self.assertEqual(machine_type, 'n1-standard-2')

    def testNumberOfNode(self):
        """ Test if the number of nodes in the node pool is as specified """
        client = cluster_manager.ClusterManagerClient()
        cluster_info = client.get_cluster(name=TestGKECluster.name)
        node_count = cluster_info.current_node_count
        self.assertEqual(node_count, 4)

    def testStatusOfServices(self):
        """ Test if all the service deployments are ready """
        command = ("kubectl get deployment --context=%s --all-namespaces -o json" % TestGKECluster.context)
        result = subprocess.run(split(command), encoding='utf-8', capture_output=True)
        services = json.loads(result.stdout)
        for service in services['items']:
            self.assertTrue(int(service['status']['readyReplicas']) >= 1)

    def testReachOfHipsterShop(self):
        """ Test if querying online boutique returns 200 """
        command = ("kubectl -n istio-system get service istio-ingressgateway --context=%s -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" % TestGKECluster.context)
        result = subprocess.run(split(command), encoding='utf-8', capture_output=True)
        external_ip = result.stdout.replace('\n', '')
        url = 'http://{0}'.format(external_ip)
        self.assertTrue(urllib.request.urlopen(url).getcode() == 200)

class TestProjectResources(unittest.TestCase):
    def testAPIEnabled(self):
        """ Test if all APIs requested are enabled """
        api_requested = ['iam.googleapis.com', 'compute.googleapis.com', 'clouddebugger.googleapis.com',
                         'cloudtrace.googleapis.com', 'clouderrorreporting.googleapis.com', 'sourcerepo.googleapis.com',
                         'container.googleapis.com']
        command = ('gcloud services list --format="value(config.name)"')
        result = subprocess.run(split(command), encoding='utf-8', capture_output=True)
        api_enabled = result.stdout.strip().split('\n')
        for api in api_requested:
            self.assertTrue(api in api_enabled)

    def testErrorReporting(self):
        """ Test if we can report error using Error Reporting API """
        client = error_reporting.Client(project=getProjectId())
        try:
            client.report("Testing reachability!")
        except exceptions.NotFound as e:
            # Error Reporting API is not enabled, so we can't report errors
            raise e      
        except Exception as e:
            # unexpected error
            raise e

def getProjectId():
    return os.environ['GOOGLE_CLOUD_PROJECT']

def getClusterZone():
    return os.environ['ZONE']

if __name__ == '__main__':
    unittest.main()
