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


def run_shell_command(command, decode_output=True):
    """
    Runs the given command and returns any output and error
    If `decode_output` is True, try to decode output and error message with 
    UTF-8 encoding, as well as removing any single quote.
    """
    process = subprocess.Popen(
        command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True
    )
    output, error = process.communicate()
    if decode_output:
        if output is not None:
            output = output.decode("utf-8").replace("'", '').strip()
        if error is not None:
            error = error.decode("utf-8").replace("'", '').strip()
    return output, error


def run_interactive_shell_command(command):
    """
    Runs the given interactive command that waits for user input and
    returns any output and error
    """
    subprocess.run(command.split())


def get_project_id():
    """Get the Google Cloud Project ID"""
    project_id, err = run_shell_command(
        "gcloud config list --format 'value(core.project)'")
    if not project_id:
        logging.warn(f"Could not retrieve project id.")
    return project_id, err


def get_external_ip():
    """Get the IP Address for the external LoadBalancer"""
    ip_addr, err = run_shell_command(
        "kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'")
    if not ip_addr:
        logging.warn(f"No external IP found.")
    return ip_addr, err


def get_loadgen_ip():
    """Get the IP Address for the load generator"""
    auth_cluster('loadgenerator')
    ip_addr, err = run_shell_command(
        "kubectl get service loadgenerator -o jsonpath='{.status.loadBalancer.ingress[0].ip}'")
    if not ip_addr:
        logging.warn(f"No loadgeen IP found.")
    auth_cluster('cloud-ops-sandbox')
    return ip_addr, err


def get_cluster_zone(project_id, cluster_name):
    """Get the zone for a cluster in a given project"""
    zone, err = run_shell_command(
        f"gcloud container clusters list --filter name:{cluster_name} --project {project_id} --format 'value(zone)'")
    if not zone:
        logging.warn(
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
    project_id, err = get_project_id()
    if err or not project_id:
        logging.error(
            f"Can't authenticate cluster. Failed too get project ID: {err}")
        exit(1)
    # Get cluster zone
    zone, err = get_cluster_zone(project_id, cluster_name)
    if err or not zone:
        logging.error(f"Can't authenticate cluster. Failed to get zone: {err}")
        exit(1)
    # Run authentication command
    _ = run_shell_command(
        f"gcloud container clusters get-credentials {cluster_name} --project {project_id} --zone {zone}")
    logging.info("Cluster has been authenticated")


def run_interactive_multiple_choice(prompt, choices, correct_answer):
    """Runs an interactive multiple choice Quiz.

    Example Layout:
        ===============================================================
                            MULTIPLE CHOICE QUIZ
        ===============================================================
        Question: Which service has an issue?
        Choices
          0: Ad
          1: Cart
          2: Checkout
          3: Currency
          4: Email
          5: Frontend
          6: Payment
          7: Product Catalog
          8: Rating
          9: Recommendation
          10: Shipping
        Enter your answer: 

    Paramters
    ---------
    prompt: string
        The question prompt to display.
    choices: string[]
        A list of potential answers to choose from.
    correct_answer: int
        The (0-based) index for the correct answer in the `choices` params.
    """
    if not choices:
        logging.info("Skipped. Empty multiple choice.")
        return

    if correct_answer < 0 or correct_answer >= len(choices):
        logging.error(
            "Correct answer is not in the pool of potential answers.")
        exit(1)

    # Show the question
    print("===============================================================")
    print("                     MULTIPLE CHOICE QUIZ                      ")
    print("===============================================================")
    print(f"Question: {prompt}")
    print("Choices")
    for i, choice in enumerate(choices):
        print(f"  {i}: {choice}")

    # Asks for answer
    while True:
        user_answer = input("Enter your answer: ").strip()
        try:
            user_answer = int(user_answer)
            if user_answer < 0 or user_answer >= len(choices):
                print("Not a valid choice")
            elif user_answer == correct_answer:
                print("Congratulations! You are correct.")
                return
            else:
                print("Incorrect. Please try again.")
        except ValueError:
            print("Please enter the number of your selected answer.")
