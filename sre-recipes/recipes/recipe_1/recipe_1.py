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

import os
import subprocess
from recipe import Recipe


class Recipe1(Recipe):
    """
    This class implements recipe 1, which purposefully
    introduces latency into the frontend service.
    """

    def __init__(self):
        self.__service = 'frontend'

    @staticmethod
    def get_relative_path(relative_path, filename, extension):
        """
        Returns the absolute path to the filename given the relative
        path to the file, filename, and file extension
        """
        dir_abs_path = os.path.dirname(os.path.abspath(__file__))
        return dir_abs_path + relative_path + filename + extension

    @staticmethod
    def get_working_path(service):
        """Returns the absolute path of the working service's kubernetes manifest"""
        return Recipe1.get_relative_path('/../../../kubernetes-manifests/', \
            service, '.yaml')

    @staticmethod
    def get_broken_path(service):
        """Returns the absolute path of the broken service's kubernetes manifest"""
        return Recipe1.get_relative_path('/', service, '.yaml')

    @staticmethod
    def get_config_map_path(recipe):
        """Returns the absolute path of the broken service's kubernetes manifest"""
        return Recipe1.get_relative_path('/', recipe, '.yaml')

    @staticmethod
    def run_command(command):
        """Runs the given command and returns any output and error"""
        process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
        output, error = process.communicate()
        return output, error

    def break_service(self):
        """
        Rolls back the working version of the given service and deploys the
        broken version of the given service
        """
        config_map = 'config_map'
        config_map_name = 'config-map'
        working_service_abs_path = Recipe1.get_working_path(self.__service)
        broken_service_abs_path = Recipe1.get_broken_path(self.__service)
        recipe_config_map_abs_path = Recipe1.get_config_map_path(config_map)

        print("Rolling back working service...")
        delete_command = 'kubectl delete -f ' + working_service_abs_path
        Recipe1.run_command(delete_command)

        print("Setting up broken service...")
        create_config_map_command = 'kubectl create configmap ' + config_map_name \
            + ' --from-file=' + recipe_config_map_abs_path
        Recipe1.run_command(create_config_map_command)

        print("Deploying broken service...")
        apply_command = 'kubectl apply -f ' + broken_service_abs_path
        Recipe1.run_command(apply_command)

        # cleaning up config map for next run to avoid a double create
        delete_config_map_command = 'kubectl delete configmap ' + config_map_name
        Recipe1.run_command(delete_config_map_command)

    def restore_service(self):
        """
        Rolls back the broken version of the given service and deploys the
        working version of the given service
        """
        working_service_abs_path = Recipe1.get_working_path(self.__service)
        broken_service_abs_path = Recipe1.get_broken_path(self.__service)

        print("Rolling back broken service...")
        delete_command = 'kubectl delete -f ' + broken_service_abs_path
        Recipe1.run_command(delete_command)

        print("Deploying working service...")
        apply_command = 'kubectl apply -f ' + working_service_abs_path
        Recipe1.run_command(apply_command)

    def verify(self):
        """Verifies the user found the root cause of the broken service"""
        print('verify')
