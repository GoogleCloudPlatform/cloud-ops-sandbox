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

import json
import os
import subprocess
import time
import unittest
from shlex import split

import requests
from google.cloud.container_v1.services import cluster_manager
from parameterized import parameterized


class TestLoadGenerator(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        """Get the location of GKE cluster for later queries"""
        cls.name = 'projects/{0}/locations/{1}/clusters/loadgenerator'.format(
            get_project_id(), get_cluster_zone())
        # authenticate container cluster
        command = ('gcloud config set project {0}'.format(get_project_id()))
        subprocess.run(split(command))
        # set kubectl context to loadgenerator
        command = (
            'gcloud container clusters get-credentials loadgenerator --zone {0}'.format(get_cluster_zone()))
        subprocess.run(split(command))
        # obtain the context name
        command = ('kubectl config current-context')
        result = subprocess.run(
            split(command), encoding='utf-8', capture_output=True)
        cls.context = result.stdout
        # obtain the public url
        command = (
            "kubectl get service loadgenerator --context=%s -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" % TestLoadGenerator.context)
        result = subprocess.run(
            split(command), encoding='utf-8', capture_output=True)
        loadgen_ip = result.stdout.replace('\n', '')
        cls.url = 'http://{0}'.format(loadgen_ip)
        cls.api_url = 'http://{0}:81'.format(loadgen_ip)

    def testNodeMachineType(self):
        """Test if the machine type for the nodes is as specified"""
        client = cluster_manager.ClusterManagerClient()
        cluster_info = client.get_cluster(name=TestLoadGenerator.name)
        machine_type = cluster_info.node_config.machine_type
        self.assertEqual(machine_type, 'n1-standard-1')

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
        self.assertTrue(get_cluster_zone() != os.environ['ZONE'])

    @parameterized.expand([(None,), ('basic',), ('step',)])
    def testStartSwarm(self, pattern):
        """
        Test if the load generation works properly when started
        Run for each loadgenerator pattern
        Start with `None` to check the default case (no explicit pattern)
        """
        if pattern:
            # reset deployment to use new pattern
            set_env_command = "kubectl set env deployment/loadgenerator " \
                f"LOCUST_TASK={pattern}"
            delete_pods_command = "kubectl delete pods -l app=loadgenerator"
            wait_command = "kubectl wait --for=condition=available" \
                " --timeout=500s deployment/loadgenerator"
            subprocess.run(split(set_env_command))
            subprocess.run(split(delete_pods_command))
            subprocess.run(split(wait_command))
        # enable swarm
        form_data = {'user_count': 1, 'spawn_rate': 1}
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

    def testApiPing(self):
        """Test if querying load generator's SRE Recipe API /ping endpoint returns 2xx"""
        r = requests.get(f"{TestLoadGenerator.api_url}/api/ping")
        self.assertTrue(r.ok)
        resp = json.loads(r.text)
        self.assertEqual(resp['msg'], "pong")

    @parameterized.expand([(10, None,), (None, 1,), ('foo', 1,), (1, 1.15,)])
    def testApiSpawnErrorOnInvalidRequiredRequestParameter(self, user_count, spawn_rate):
        """
        Test if querying load generator's SRE Recipe API /spawn endpoint returns
        error for invalid form data format for required parameters.

        Specifically, we expect both user_count and spawn_rate to be required,
        non-zero, valid integers.
        """
        form_data = {}
        if user_count:
            form_data["user_count"] = user_count
        if spawn_rate:
            form_data["spawn_rate"] = spawn_rate

        r = requests.post(
            f"{TestLoadGenerator.api_url}/api/spawn/BasicPurchasingUser", form_data)
        self.assertFalse(r.ok)
        self.assertEqual(r.status_code, 400)
        resp = json.loads(r.text)
        self.assertTrue(len(resp.get("err", "")) > 0)

    @parameterized.expand([('foo',), (1.15,)])
    def testApiSpawnErrorOnInvalidOptionalRequestParameter(self, stop_after):
        """
        Test if querying load generator's SRE Recipe API /spawn endpoint returns
        error for invalid form data format for optional parameters.

        Specifically, we expect the stop_after to be valid integers.
        """
        form_data = {
            "user_count": 10,
            "spawn_rate": 1,
            "stop_after": stop_after
        }
        r = requests.post(
            f"{TestLoadGenerator.api_url}/api/spawn/BasicPurchasingUser", form_data)
        self.assertFalse(r.ok)
        self.assertEqual(r.status_code, 400)
        resp = json.loads(r.text)
        self.assertTrue(len(resp.get("err", "")) > 0)

    def testApiSpawnErrorOnUserNotFound(self):
        """
        Test if querying load generator's SRE Recipe API /spawn endpoint returns
        error for unknown user class
        """
        r = requests.post(
            f"{TestLoadGenerator.api_url}/api/spawn/NotExistUser", {'user_count': 1, 'spawn_rate': 1})
        self.assertFalse(r.ok)
        self.assertEqual(r.status_code, 404)
        resp = json.loads(r.text)
        self.assertEqual(
            resp['err'], "Cannot find SRE Recipe Load for: NotExistUser")

    def testApiSpawnEndToEnd(self):
        """
        Test if starting load using load generator's SRE Recipe API /spawn 
        endpoint actually generated load, with timeout, correctly.

        We do not separate them into different tests for now, due to possible
        race conditions between concurrent execution of tests
        """

        # spawn some users and auto stop after 20 seconds for cleanup
        form_data = {'user_count': 10, 'spawn_rate': 5, "stop_after": 20}
        r = requests.post(
            f"{TestLoadGenerator.api_url}/api/spawn/BasicPurchasingUser", form_data)
        self.assertTrue(r.ok)
        resp = json.loads(r.text)
        self.assertEqual(
            resp['msg'], "Spawn Request Received: spawning 10 users at 5 users/second")

        tries = 0
        all_users_spawned = False
        has_rps = False
        while tries < 10 and not (all_users_spawned and has_rps):
            time.sleep(1)
            resp = requests.get(f"{TestLoadGenerator.api_url}/stats/requests")
            self.assertTrue(resp.ok)
            stats = json.loads(resp.text)
            if stats["user_count"] == 10:
                all_users_spawned = True
            if stats["total_rps"] > 0:
                has_rps = True
            tries += 1
        self.assertTrue(all_users_spawned and has_rps)

        # wait 20 more seconds and check if users are being stopped
        # This give us a plenty of buffer for auto stop conditions
        time.sleep(20)
        resp = requests.get(f"{TestLoadGenerator.api_url}/stats/requests")
        self.assertTrue(resp.ok)
        stats = json.loads(resp.text)
        self.assertLess(stats["user_count"], 10)


def get_project_id():
    return os.environ['GOOGLE_CLOUD_PROJECT']


def get_cluster_zone():
    return os.environ['LOADGEN_ZONE']


if __name__ == '__main__':
    unittest.main()
