# Copyright 2021 Google LLC
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

from os import path
import subprocess
import logging
import yaml

# A convenient library of common commands
COMMAND_LIB = {
    "GET_EXTERNAL_IP": "kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'",
    "GET_GCLOUD_PROJECT_ID": "gcloud config list --format value(core.project)",
    "GET_GCLOUD_CLUSTER_ZONE": "gcloud container clusters list --filter name:{cluster_name} --project {project_id} --format value(zone)",
    "GET_GCLOUD_CLUSTER_AUTH_COMMAND": "gcloud container clusters get-credentials {cluster_name} --project {project_id} --zone {zone}",
}


class RecipeRunner:

    def __init__(self):
        self.config_root_dir = path.join(
            path.dirname(path.abspath(__file__)), "configs")

    def load_recipe(self, name):
        """Load a SRE Recipe in YAML config format"""
        with open(path.join(self.config_root_dir, f"{name}.yaml")) as file:
            config = yaml.load(file.read())
            return config

    ############################## Shell Commands #############################

    def run_command(self, command, decode_output=True):
        """
        Runs the given command and returns any output and error
        If `decode_output` is True, try to decode output with UTF-8 encoding,
        as well as removing any single quote.
        """
        process = subprocess.Popen(
            command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        output, error = process.communicate()
        if output is not None and decode_output:
            output = output.decode("utf-8").replace("'", '')
        return output, error

    ####################### GCloud & Kubernetes Commands #######################

    def get_project_id(self):
        """Get the Google Cloud Project ID"""
        project_id, err = self.run_command(
            COMMAND_LIB["GET_GCLOUD_PROJECT_ID"])
        if not project_id:
            logging.error(f"Could not retrieve project id: {err}")
        return project_id, err

    def get_external_ip(self):
        """Get the IP Address for the external loadBalancer"""
        ip_addr, err = self.run_command(
            COMMAND_LIB["GET_EXTERNAL_IP"])
        if not ip_addr:
            logging.error(f"No external IP found: {err}")
        return ip_addr, err

    def get_cluster_zone(self, project_id, cluster_name):
        zone, err = self.run_command(
            COMMAND_LIB["GET_GCLOUD_CLUSTER_ZONE"].format(
                project_id=project_id, cluster_name=cluster_name))
        if not zone:
            logging.error(
                f"No zone found for {cluster_name} in project {project_id}"
            )
        return zone, err

    def auth_cluster(self, cluster_name="cloud-ops-sandbox"):
        """
        Authenticates cluster with kubectl commands.

        @param cluster_name: the Kubernetes cluster name
                Options: 
                  - cloud-ops-sandbox
                  - loadgenerator
        """
        logging.info("Trying to authenticate cluster...")
        # Locate project ID
        project_id, _ = self.get_project_id()
        if not project_id:
            logging.error("Can't authenticate cluster. No project ID found.")
            exit(1)
        # Get cluster zone
        zone, _ = self.get_cluster_zone(project_id, cluster_name)
        if not zone:
            logging.error("Can't authenticate cluster. No zone found.")
            exit(1)
        # Get authentication command
        auth_command, err = self.run_command(
            COMMAND_LIB["GET_GCLOUD_CLUSTER_AUTH_COMMAND"].format(
                project_id=project_id, cluster_name=cluster_name, zone=zone))
        if not auth_command:
            logging.error("Can't get authentication command")
            exit(1)
        # Authenticate!
        _ = self.run_command(auth_command, decode_output=False)
        logging.info("Cluster has been authenticated")


runner = RecipeRunner()
# print(runner.load_recipe("recipe2"))
print(runner.auth_cluster())
