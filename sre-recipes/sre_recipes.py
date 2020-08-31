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
## This CLI is the interface for sre recipes. It 
## deploys and rolls back broken services.
####################################################################

import os
import subprocess
import click

dir_abs_path = os.path.dirname(os.path.abspath(__file__))
recipe_service_mapping = {'recipe-1': 'frontend'}


# Returns the absolute path to the filename given the relative
# path to the file, filename, and file extension
def get_relative_path(relative_path, filename, extension):
    return dir_abs_path + relative_path + filename + extension


# Returns the absolute path of the working service's kubernetes manifest
def get_working_path(service):
    return get_relative_path('/../kubernetes-manifests/', service, '.yaml')


# Returns the absolute path of the broken service's kubernetes manifest
def get_broken_path(service):
    return get_relative_path('/kubernetes-manifests/', service, '.yaml')


# Returns the absolute path of the broken service's kubernetes manifest
def get_config_map_path(recipe):
    return get_relative_path('/config-maps/', recipe.replace('-', '_'), '.yaml')


# Runs the given command and returns any output and error
def run_command(command):
    process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
    output, error = process.communicate()
    return output, error


# Rolls back the working version of the given service and deploys the
# broken version of the given service
def break_func(recipe):
    service = recipe_service_mapping[recipe]
    working_service_abs_path = get_working_path(service)
    broken_service_abs_path = get_broken_path(service)
    recipe_config_map_abs_path = get_config_map_path(recipe)

    print("Rolling back working service...")
    delete_command = 'kubectl delete -f ' + working_service_abs_path
    output, error = run_command(delete_command)

    print("Setting up broken service...")
    create_config_map_command = 'kubectl create configmap ' + recipe \
        + ' --from-file=' + recipe_config_map_abs_path
    output, error = run_command(create_config_map_command)

    print("Deploying broken service...")
    apply_command = 'kubectl apply -f ' + broken_service_abs_path
    output, error = run_command(apply_command)

    # cleaning up config map for next run to avoid a double create
    delete_config_map_command = 'kubectl delete configmap ' + recipe
    output, error = run_command(delete_config_map_command)


# Rolls back the broken version of the given service and deploys the
# working version of the given service
def restore(recipe):
    service = recipe_service_mapping[recipe]
    working_service_abs_path = get_working_path(service)
    broken_service_abs_path = get_broken_path(service)

    print("Rolling back broken service...")
    delete_command = 'kubectl delete -f ' + broken_service_abs_path
    output, error = run_command(delete_command)

    print("Deploying working service...")
    apply_command = 'kubectl apply -f ' + working_service_abs_path
    output, error = run_command(apply_command)


@click.command()
@click.argument('action', type=click.Choice(['break', 'restore', 'verify']))
@click.argument('recipe', type=click.Choice(recipe_service_mapping.keys()))
def main(action, recipe):
    if action == 'break':
        break_func(recipe)
    elif action == 'restore':
        restore(recipe)
    elif action == 'verify':
        print('verify!')

if __name__ == "__main__":
    main()
