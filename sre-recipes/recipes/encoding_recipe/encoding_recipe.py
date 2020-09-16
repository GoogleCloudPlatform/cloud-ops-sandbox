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

# -*- coding: utf-8 -*-
"""
This module contains the implementation of recipe 1
"""

import logging
import subprocess
from recipe import Recipe


class EncodingRecipe(Recipe):
    """
    This class implements recipe 1, which purposefully
    spits errors from the Email Service.
    """

    def deploy_state(state):
        """
        Sets an environment variable ENCODE_EMAIL to given state
        and updates the state accordingly
        """
        state_str = str(state).lower()
        set_env_command = f"kubectl set env deployment/emailservice ENCODE_EMAIL={state_str}"
        get_pod_command = """kubectl get pod -l app=emailservice -o \
            jsonpath=\"{.items[0].metadata.name}\""""
        logging.info('Setting env variable: %s', set_env_command)
        logging.info('Getting pod: %s', get_pod_command)

        Recipe._run_command(set_env_command)
        service, error = Recipe._run_command(get_pod_command)
        service = service.decode("utf-8").replace('"', '')
        delete_pod_command = f"kubectl delete pod {service}"
        logging.info('Deleting pod: %s', delete_pod_command)
        Recipe._run_command(delete_pod_command)

    def break_service(self):
        """
        Rolls back the working version of the given service and deploys the
        broken version of the given service
        """
        print("Deploying broken service...")
        Recipe._auth_cluster()
        self.deploy_state(True)
        print("Done")
        logging.info('Deployed broken service')

    def restore_service(self):
        """
        Rolls back the broken version of the given service and deploys the
        working version of the given service
        """
        print("Deploying working service...")
        Recipe._auth_cluster()
        self.deploy_state(False)
        print("Done")
        logging.info('Deployed working service')

    def hint(self):
        """
        Provides a hint about the root cause of the issue
        """
        get_project_command = "gcloud config list --format value(core.project)"
        project_id, error = Recipe._run_command(get_project_command)
        project_id = project_id.decode("utf-8").replace('"', '')
        print('Use Cloud Logging to view logs exported by each service: https://console.cloud.google.com/logs?project={}'.format(project_id))

    def verify_broken_service(self):
        """
        Displays a multiple choice quiz to the user about which service
        broke and prompts the user for an answer
        """
        prompt = 'Which service has a breakage?'
        choices = ['email service', 'recommendation service', 'productcatalog service', 'cart service', 'frontend service']
        answer = 'email service'
        Recipe._generate_multiple_choice(prompt, choices, answer)

    def verify_broken_cause(self):
        """
        Displays a multiple choice quiz to the user about the cause of
        the breakage and prompts the user for an answer
        """
        prompt =  'What was the cause of the break?'
        choices = ['high latency', 'internal service errors', 'failed connection to other services', 'memory quota exceeded']
        answer = 'internal service errors'
        Recipe._generate_multiple_choice(prompt, choices, answer)

    def verify(self):
        """Verifies the user found the root cause of the broken service"""
        print('This is a multiple choice quiz to verify that you have')
        print('found the root cause of the break')
        self.verify_broken_service()
        self.verify_broken_cause()
        print('Good job! You have correctly identified which service broke')
        print('and what caused it to break!')
