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

####################################################################
## This CLI handles the deploying broken services and rolling
## broken services back. 
####################################################################

import os
import subprocess
import click

dir_abs_path = os.path.dirname(os.path.abspath(__file__))
manifest_abs_path = dir_abs_path + '/../kubernetes-manifests/'

# Returns the absolute path of the working service's kubernetes manifest
# and the broken service's kubernetes manifest
def get_paths(service):
    working_service_abs_path = manifest_abs_path + service + ".yaml"
    broken_service_abs_path = manifest_abs_path + service + "srerecipes.yaml"
    return working_service_abs_path, broken_service_abs_path


# Runs the given command and returns any output and error
def run_command(command):
    process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
    output, error = process.communicate()
    return output, error


# Rolls back the working version of the given service and deploys the
# broken version of the given service
def break_func(service):
    working_service_abs_path, broken_service_abs_path = get_paths(service)

    print("Rolling back working " + service + " service...")
    delete_command = 'kubectl delete -f ' + working_service_abs_path
    output, error = run_command(delete_command)

    print("Deploying broken " + service + " service...")
    apply_command = 'kubectl apply -f ' + broken_service_abs_path
    output, error = run_command(apply_command)


# Rolls back the broken version of the given service and deploys the
# working version of the given service
def restore(service):
    working_service_abs_path, broken_service_abs_path = get_paths(service)

    print("Rolling back broken " + service + " service...")
    delete_command = 'kubectl delete -f ' + broken_service_abs_path
    output, error = run_command(delete_command)

    print("Deploying working " + service + " service...")
    apply_command = 'kubectl apply -f ' + working_service_abs_path
    output, error = run_command(apply_command)


@click.command()
@click.argument('action', type=click.Choice(['break', 'restore', 'verify']))
@click.argument('service', type=click.Choice(['frontend']))
def main(action, service):
    if action == 'break':
        break_func(service)
    elif action == 'restore':
        restore(service)
    elif action == 'verify':
        print('verify!')

if __name__ == "__main__":
    main()
    