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


class CurrenciesRecipe(Recipe):
    """
    This class implements recipe 1, which purposefully
    introduces latency into the frontend service.
    """

    @staticmethod
    def _run_command(command):
        """Runs the given command and returns any output and error"""
        process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
        output, error = process.communicate()
        return output, error

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

        CurrenciesRecipe._run_command(set_env_command)
        service, error = CurrenciesRecipe._run_command(get_pod_command)
        service = service.decode("utf-8").replace('"', '')
        delete_pod_command = f"kubectl delete pod {service}"
        logging.info('Deleting pod: %s', delete_pod_command)
        CurrenciesRecipe._run_command(delete_pod_command)

    @staticmethod
    def _auth_cluster():
        """ Authenticates for kubectl commands. """
        logging.info('Authenticating cluster')
        get_project_command = "gcloud config list --format value(core.project)"
        project_id, error = CurrenciesRecipe._run_command(get_project_command)
        project_id = project_id.decode("utf-8").replace('"', '')
        zone_command = "gcloud container clusters list --filter name:cloud-ops-sandbox --project {} --format value(zone)".format(project_id)
        zone, error = CurrenciesRecipe._run_command(zone_command)
        zone = zone.decode("utf-8").replace('"', '')
        auth_command = "gcloud container clusters get-credentials cloud-ops-sandbox --zone {}".format(zone)
        CurrenciesRecipe._run_command(auth_command)
        logging.info('Cluster has been authenticated')

    def break_service(self):
        """
        Rolls back the working version of the given service and deploys the
        broken version of the given service
        """
        print("Deploying broken service...")
        self._auth_cluster()
        self._deploy_state(True)
        print("Done")
        logging.info('Deployed broken service')

    def restore_service(self):
        """
        Rolls back the broken version of the given service and deploys the
        working version of the given service
        """
        print("Deploying working service...")
        self._auth_cluster()
        self._deploy_state(False)
        print("Done")
        logging.info('Deployed working service')

    def _service_multiple_choice(self):
        """
        Displays a multiple choice quiz to the user about which service
        broke and prompts the user for an answer
        """
        print("Which service broke?\n"
                "\t[a] ad service \n"
                "\t[b] cart service \n"
                "\t[c] checkout service \n"
                "\t[d] currency service \n"
                "\t[e] email service \n"
                "\t[f] frontend service \n"
                "\t[g] payment service \n"
                "\t[h] product catalog service \n"
                "\t[i] recommendation service \n"
                "\t[j] redis \n"
                "\t[k] shipping service")
        answer = input('Your answer: ')
        return answer

    def _cause_multiple_choice(self):
        """
        Displays a multiple choice quiz to the user about the cause of
        the breakage and prompts the user for an answer
        """
        print('What caused the breakage?')
        print('\t[a] failed connections to other services')
        print('\t[b] high memory usage')
        print('\t[c] high latency')
        print('\t[d] dropped requests')
        answer = input('Your answer: ')
        return answer

    def _verify_broken_service(self):
        """Verifies the user found which service broke"""
        answer = self._service_multiple_choice()
        while answer.lower() != 'f':
            print('Incorrect. Please try again.')
            answer = input('Your answer: ')
        print('Correct! The frontend service is broken.')

    def _verify_broken_cause(self):
        """Verifies the user found the root cause of the breakage"""
        answer = self._cause_multiple_choice()
        while answer.lower() != 'c':
            print('Incorrect. Please try again.')
            answer = input('Your answer: ')
        print('Correct! High latency caused the breakage.')

    def verify(self):
        """Verifies the user found the root cause of the broken service"""
        print("This is a multiple choice quiz to verify that you've")
        print('found the root cause of the break')
        self._verify_broken_service()
        self._verify_broken_cause()
        print('Good job! You have correctly identified which service broke')
        print('and what caused it to break!')
