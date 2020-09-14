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
This module contains an abstract base class that defines the required
behavior of each recipe.
"""

import abc
import subprocess
import logging

class Recipe(abc.ABC):
    """
    This abstract base class outlines the required behavior of a recipe.
    """

    @abc.abstractmethod
    def break_service(self):
        """Deploys the broken service"""

    @abc.abstractmethod
    def restore_service(self):
        """Restores working condition"""

    @abc.abstractmethod
    def verify(self):
        """
        Verifies that the user of the recipe found the root cause
        of the breakage
        """

    @abc.abstractmethod
    def hint(self):
        """
        Provides a hint about the root cause of the issue
        """

    @staticmethod
    def _run_command(command):
        """Runs the given command and returns any output and error"""
        process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
        output, error = process.communicate()
        return output, error

    @staticmethod
    def _auth_cluster():
        """ Authenticates for kubectl commands. """
        logging.info('Authenticating cluster')
        get_project_command = "gcloud config list --format value(core.project)"
        project_id, error = Recipe._run_command(get_project_command)
        project_id = project_id.decode("utf-8").replace('"', '')
        zone_command = "gcloud container clusters list --filter name:cloud-ops-sandbox --project {} --format value(zone)".format(project_id)
        zone, error = Recipe._run_command(zone_command)
        zone = zone.decode("utf-8").replace('"', '')
        auth_command = "gcloud container clusters get-credentials cloud-ops-sandbox --project {} --zone {}".format(project_id, zone)
        Recipe._run_command(auth_command)
        logging.info('Cluster has been authenticated')


