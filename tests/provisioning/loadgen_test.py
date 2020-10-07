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
from parameterized import parameterized
import subprocess
from shlex import split
import json
import requests
import time

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
        # obtain the context name
        command=('kubectl config current-context')
        result = subprocess.run(split(command), encoding='utf-8', capture_output=True)
        cls.context = result.stdout
        # obtain the public url
        command = ("kubectl get service loadgenerator --context=%s -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" % TestLoadGenerator.context)
        result = subprocess.run(split(command), encoding='utf-8', capture_output=True)
        loadgen_ip = result.stdout.replace('\n', '')
        cls.url = 'http://{0}'.format(loadgen_ip)


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
        self.assertTrue(node_count == 1)

    def testReachOfLoadgen(self):
        """Test if querying load generator returns 2xx"""
        r = requests.get(TestLoadGenerator.url)
        self.assertTrue(r.ok)

    def testDifferentZone(self):
        """Test if load generator cluster is in a different zone from the Hipster Shop cluster"""
        self.assertTrue(getClusterZone() != os.environ['ZONE'])

    @parameterized([None, basic, step])
    def testStartSwarm(self, pattern):
        """
        Test if the load generation works properly when started
        Run for each loadgenerator pattern
        Start with `None` to check the default case (no explicit pattern)
        """
        if pattern:
            # reset deployment to use new pattern
            set_env_command = "kubectl set env deployment/loadgenerator " \
                                f"LOCUST_TASK={pattern}_locustfile.py"
            delete_pods_command = "kubectl delete pods -l app=loadgenerator"
            wait_command = "kubectl wait --for=condition=available" \
                            " --timeout=500s deployment/loadgenerator"
            subprocess.run(split(set_env_command))
            subprocess.run(split(delete_pods_command))
            subprocess.run(split(wait_command))
        # enable swarm
        form_data = {'user_count':1, 'spawn_rate':1}
        requests.post(f"{TestLoadGenerator.url}/swarm", form_data)
        # wait for valid request in case of startup errors
        success, tries = False, 0
        while not success and tries < 10:
            tries += 1
            time.sleep(2)
            response = requests.get(f"{TestLoadGenerator.url}/stats/requests")
            if response.ok:
                stats = json.loads(response.text)
                success = (stats['total_rps'] > 0)
        # assert expected values from response
        self.assertTrue(response.ok)
        self.assertEqual(stats['state'], 'running')
        self.assertEqual(stats['errors'], [])
        self.assertTrue(stats['user_count'] > 0)
        self.assertTrue(stats['total_rps'] > 0)

def getProjectId():
    return os.environ['GOOGLE_CLOUD_PROJECT']

def getClusterZone():
    return os.environ['LOADGEN_ZONE']

if __name__ == '__main__':
    unittest.main()
