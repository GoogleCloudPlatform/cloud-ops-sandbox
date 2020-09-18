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
This module contains the implementation of recipe 0
"""

import logging
import subprocess
from recipe import Recipe


class CurrenciesRecipe(Recipe):
    """
    This class implements recipe 0, which purposefully
    introduces latency into the frontend service.
    """
    name = "currency_recipe"
    
    def get_name(self):
        return self.name

    @staticmethod
    def _deploy_state(state):
        """
        Sets an environment variable CONVERT_CURRENCIES to given state
        and updates the state accordingly
        """
        state_str = str(state).lower()
        set_env_command = f"kubectl set env deployment/frontend CONVERT_CURRENCIES={state_str}"
        get_pod_command = """kubectl get pod -l app=frontend -o \
            jsonpath=\"{.items[0].metadata.name}\""""
        logging.info('Setting env variable: %s', set_env_command)
        logging.info('Getting pod: %s', get_pod_command)

        Recipe._run_command(set_env_command)
        service, error = Recipe._run_command(get_pod_command)
        service = service.decode("utf-8").replace('"', '')
        if not service:
            print('No service found. Could not deploy state.')
            logging.error('No service found. Could not deploy state.')
        delete_pod_command = f"kubectl delete pod {service}"
        logging.info('Deleting pod: %s', delete_pod_command)
        Recipe._run_command(delete_pod_command)

    def break_service(self):
        """
        Rolls back the working version of the given service and deploys the
        broken version of the given service
        """
        print('Deploying broken service...')
        Recipe._auth_cluster()
        self._deploy_state(True)
        print('Done')
        logging.info('Deployed broken service')

    def restore_service(self):
        """
        Rolls back the broken version of the given service and deploys the
        working version of the given service
        """
        print('Deploying working service...')
        Recipe._auth_cluster()
        self._deploy_state(False)
        print('Done')
        logging.info('Deployed working service')

    def hint(self):
        """
        Provides a hint about finding the root cause of this recipe
        """
        print('Giving hint for recipe')
        Recipe._auth_cluster()
        external_ip_command = "kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
        ip, error = Recipe._run_command(external_ip_command)
        ip = ip.decode("utf-8").replace("'", '')
        if not ip:
            print('No external IP found.')
            logging.error('No external IP found.')
            exit(1)
        print('Visit the external IP of the demo application to see if there are any visible changes: http://{}'.format(ip))
        get_project_command = "gcloud config list --format value(core.project)"
        project_id, error = Recipe._run_command(get_project_command)
        project_id = project_id.decode("utf-8").replace('"', '')
        if not project_id:
            print('No project ID found.')
            logging.error('No project ID found.')
            exit(1)
        print('Use Monitoring Dashboards to see metrics associated with each service: https://console.cloud.google.com/monitoring/dashboards?project={}'.format(project_id))

    def verify_broken_service(self):
        """
        Displays a multiple choice quiz to the user about which service
        broke and prompts the user for an answer
        """
        prompt = 'Which service has a breakage?'
        choices = ['email service', 'frontend service', 'ad service', 'recommendation service', 'currency service']
        answer = 'frontend service'
        Recipe._generate_multiple_choice(prompt, choices, answer)

    def verify_broken_cause(self):
        """
        Displays a multiple choice quiz to the user about the cause of
        the breakage and prompts the user for an answer
        """
        prompt = 'What caused the breakage?'
        choices = ['failed connections to other services', 'high memory usage', 'high latency', 'dropped requests']
        answer = 'high latency'
        Recipe._generate_multiple_choice(prompt, choices, answer)

    def verify(self):
        """Verifies the user found the root cause of the broken service"""
        print(
        '''
        This is a multiple choice quiz to verify that 
        you have found the root cause of the breakage.
        '''
            )
        self.verify_broken_service()
        self.verify_broken_cause()
        print(
        '''
        Good job! You have correctly identified which 
        service broke and what caused it to break.
        '''
            )
