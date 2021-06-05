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

import subprocess
import logging


# A convenient library of common commands
COMMAND_LIB = {
    "GET_EXTERNAL_IP": "kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{{.status.loadBalancer.ingress[0].ip}}'",
    "GET_GCLOUD_PROJECT_ID": "gcloud config list --format value(core.project)",
    "GET_GCLOUD_CLUSTER_ZONE": "gcloud container clusters list --filter name:{cluster_name} --project {project_id} --format value(zone)",
    "GET_GCLOUD_CLUSTER_AUTH_COMMAND": "gcloud container clusters get-credentials {cluster_name} --project {project_id} --zone {zone}",
    "SET_ENV_VAR": "kubectl set env {service} {key_value_pairs}",
    "WAIT_FOR_SERVICE": "kubectl wait --for=condition={condition} --timeout={timeout} {service}",
    "GET_POD_NAME_BY_SELECTOR": "kubectl get pod -l {selector} -o jsonpath='{{.items[0].metadata.name}}'",
    "DELETE_POD_BY_NAME": "kubectl delete pod {name}",
}


def run_command(command, decode_output=True):
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
        output = output.decode("utf-8").replace("'", '').strip()
    return output, error

####################### GCloud & Kubernetes Commands #######################


def get_project_id():
    """Get the Google Cloud Project ID"""
    project_id, err = run_command(
        COMMAND_LIB["GET_GCLOUD_PROJECT_ID"])
    if not project_id:
        logging.error(f"Could not retrieve project id: {err}")
    return project_id, err


def get_external_ip():
    """Get the IP Address for the external LoadBalancer"""
    ip_addr, err = run_command(
        COMMAND_LIB["GET_EXTERNAL_IP"])
    if not ip_addr:
        logging.error(f"No external IP found: {err}")
    return ip_addr, err


def get_cluster_zone(project_id, cluster_name):
    """Get the zone for a cluster in a given project"""
    zone, err = run_command(
        COMMAND_LIB["GET_GCLOUD_CLUSTER_ZONE"].format(
            project_id=project_id, cluster_name=cluster_name))
    if not zone:
        logging.error(
            f"No zone found for {cluster_name} in project {project_id}"
        )
    return zone, err


def auth_cluster(cluster_name="cloud-ops-sandbox"):
    """
    Authenticates cluster with kubectl commands.

    @param cluster_name: the Kubernetes cluster name
            Options:
              - cloud-ops-sandbox
              - loadgenerator
    """
    logging.info("Trying to authenticate cluster...")
    # Locate project ID
    project_id, _ = get_project_id()
    if not project_id:
        logging.error("Can't authenticate cluster. No project ID found.")
        exit(1)
    # Get cluster zone
    zone, _ = get_cluster_zone(project_id, cluster_name)
    if not zone:
        logging.error("Can't authenticate cluster. No zone found.")
        exit(1)
    # Get authentication command
    auth_command, err = run_command(
        COMMAND_LIB["GET_GCLOUD_CLUSTER_AUTH_COMMAND"].format(
            project_id=project_id, cluster_name=cluster_name, zone=zone))
    if not auth_command:
        logging.error("Can't get authentication command")
        exit(1)
    # Authenticate!
    run_command(auth_command, decode_output=False)
    logging.info("Cluster has been authenticated")


def set_env_vars(service, key_value_pairs):
    """Set the environment variable for a kubernetes service"""
    run_command(
        COMMAND_LIB["SET_ENV_VAR"].format(
            service=service, key_value_pairs=key_value_pairs))


def wait_for_service(service, timeout_seconds, condition):
    """Wait for a kubernetes service on a condition, with timeout."""
    run_command(
        COMMAND_LIB["WAIT_FOR_SERVICE"].format(
            service=service,
            timeout=f"{timeout_seconds}s",
            condition=condition))


def get_pod_name_by_selector(selector):
    """Get the pod name by a selector string"""
    name, err = run_command(
        COMMAND_LIB["GET_POD_NAME_BY_SELECTOR"].format(selector=selector))
    if not name:
        logging.error(
            f"No pod name found with selector '{selector}': {err}")
    return name, err


def delete_pod_by_name(name):
    """Delete a Kubernetes pod"""
    run_command(
        COMMAND_LIB["DELETE_POD_BY_NAME"].format(name=name))
