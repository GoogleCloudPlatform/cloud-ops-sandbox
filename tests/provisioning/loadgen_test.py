#!/usr/bin/env python3
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

class TestLoadGenerator(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        """Get the location of GKE cluster for later queries"""
        cls.name = 'projects/{0}/locations/{1}/clusters/loadgenerator'.format(getProjectId(), getClusterZone())
        # authenticate container cluster
        command=('gcloud config set project {0}'.format(getProjectId()))
        subprocess.run(split(command))
        # set kubectl context to loadgenerator
        command=('gcloud container clusters get-credentials loadgenerator --zone {0}'.format(getClusterZone()))
        subprocess.run(split(command))

    def testNodeMachineType(self):
        """Test if the machine type for the nodes is as specified"""
        client = cluster_manager.ClusterManagerClient()
        cluster_info = client.get_cluster(name=TestLoadGenerator.name)
        machine_type = cluster_info.node_config.machine_type
        self.assertEqual(machine_type, 'n1-standard-2')

    def testNumberOfNode(self):
        """Test if the number of nodes in the node pool is as specified"""
        client = cluster_manager.ClusterManagerClient()
        cluster_info = client.get_cluster(name=TestLoadGenerator.name)
        node_count = cluster_info.current_node_count
        self.assertTrue(node_count == 3)

    def testReachOfLoadgen(self):
        """Test if querying load generator returns 200"""
        command = ("kubectl get service locust-main --context=loadgenerator -o jsonpath='{.status.loadBalancer.ingress[0].ip}'")
        result = subprocess.run(split(command), encoding='utf-8', capture_output=True)
        loadgen_ip = result.stdout.replace('\n', '')
        url = 'http://{0}:8089'.format(loadgen_ip)
        self.assertTrue(urllib.request.urlopen(url).getcode() == 200)

    def testDifferentZone(self):
        """Test if load generator cluster is in a different zone from the Hipster Shop cluster"""
        self.assertTrue(getClusterZone() != os.environ['ZONE'])

def getProjectId():
    return os.environ['GOOGLE_CLOUD_PROJECT']

def getClusterZone():
    return os.environ['LOADGEN_ZONE']

if __name__ == '__main__':
    unittest.main()
