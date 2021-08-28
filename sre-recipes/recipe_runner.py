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

import abc
import importlib
import requests
import subprocess
import yaml

from inspect import isclass
from os import path

import utils
from recipes.impl_based.base import BaseRecipeImpl


# Default Load Generation Config
DEFAULT_LOADGEN_USER_TYPE = "BasicHomePageViewingUser"
DEFAULT_LOADGEN_USER_COUNT = 20
DEFAULT_LOADGEN_SPAWN_RATE = 1
DEFAULT_LOADGEN_TIMEOUT_SECONDS = 600


class ImplBasedRecipeRunner:
    """A SRE Recipe runner for running recipes implemented as class objects.

    Given a `recipe_name`, it tries to run `recipes/impl_based/recipe_name.py`.

    This runner will propgate all exceptions to the caller, and it is caller's
    responsibility to handle any exception and to perform any error logging.
    """

    def __init__(self, recipe_name):
        self.recipe = None
        module = importlib.import_module(f"recipes.impl_based.{recipe_name}")
        for attribute_name in dir(module):
            attr = getattr(module, attribute_name)
            if isclass(attr) and attr is not BaseRecipeImpl and issubclass(attr, BaseRecipeImpl):
                self.recipe = attr()
                break
        if not self.recipe:
            raise NotImplementedError(
                f"No valid implementation exists for `{recipe_name}` recipe.")

    def get_name(self):
        return self.recipe.get_name()

    def get_description(self):
        return self.recipe.get_description()

    def run_break(self):
        return self.recipe.run_break()

    def run_restore(self):
        return self.recipe.run_restore()

    def run_hint(self):
        return self.recipe.run_hint()

    def run_verify(self):
        return self.recipe.run_verify()


class ConfigBasedRecipeRunner:
    """A SRE Recipe runner for running recipes implemented using configs.

    Given a `recipe_name`, it tries to load `recipes/configs_based/recipe_name.yaml`.

    This runner will propgate all exceptions to the caller, and it is caller's
    responsibility to handle any exception and to perform any error logging.
    """

    def __init__(self, recipe_name):
        filepath = path.join(path.dirname(
            path.abspath(__file__)), f"recipes/configs_based/{recipe_name}.yaml")
        with open(filepath, "r") as file:
            self.recipe = yaml.safe_load(file.read())
        if not self.recipe:
            raise ValueError("Cannot parse config as YAML.")

    def get_name(self):
        return self.recipe.get("name", "No name found")

    def get_description(self):
        return self.recipe.get("description", "No description found")

    ############################ Run Recipe ###################################

    @ property
    def config(self):
        return self.recipe.get("config", {})

    def run_break(self):
        print('Deploying broken service...')
        self.__handle_actions(self.config.get("break", {}))
        print('Done. Deployed broken service')

    def run_restore(self):
        print('Restoring broken service...')
        self.__handle_actions(self.config.get("restore", {}))
        print('Done. Restored broken service to working state.')

    def run_hint(self):
        hint = self.config.get("hint", None)
        if hint:
            print(f'Here is your hint!\n\n{hint}')
        else:
            print("This recipe has no hints.")

    def run_verify(self):
        verify_config = self.config.get("verify", {})
        if not verify_config:
            raise NotImplementedError("Verify is not configured")

        affected_service_config = verify_config.get("affected_service", {})
        if affected_service_config:
            if "answer" not in affected_service_config:
                raise ValueError(
                    "Correct answer is not specified for affected service quiz.")
            elif "choices" not in affected_service_config:
                raise ValueError(
                    "No answer choices configured in affected service quiz.")
            utils.run_interactive_multiple_choice(
                "Which service has an issue?",
                affected_service_config["choices"],
                affected_service_config["answer"])

        incident_cause_config = verify_config.get("incident_cause", {})
        if incident_cause_config:
            if "answer" not in incident_cause_config:
                raise ValueError(
                    "Correct answer is not specified for incident cause quiz.")
            elif "choices" not in incident_cause_config:
                raise ValueError(
                    "No answer choices configured in incident cause quiz.")
            utils.run_interactive_multiple_choice(
                "What was the cause of the issue?",
                incident_cause_config["choices"],
                incident_cause_config["answer"])

    ########################## Recipe Action Handlers ##########################

    def __handle_actions(self, actions):
        """
        Dispatch and handle a list of actions synchronously.

        Paramters
        ---------
        actions: a list of dictionary of paramters.
            Example: [{'run': 'echo "Hello World!"'}]
        """
        loadgen_ip = None

        for action in actions:
            if "run" in action:
                output, err = utils.run_shell_command(action["run"])
                if err:
                    raise RuntimeError(f"Failed to run action {action}: {err}")
            elif "loadgen" in action:
                if not loadgen_ip:
                    loadgen_ip, err = utils.get_loadgen_ip()
                    if err:
                        raise RuntimeError(f"Failed to get loadgen IP: {err}")
                if action["loadgen"] == "stop":
                    resp = requests.post(f"http://{loadgen_ip}:81/api/stop")
                    if not resp.ok:
                        raise RuntimeError(
                            f"Failed to stop existing load generation: {resp.status_code} {resp.reason}")
                elif action["loadgen"] == "spawn":
                    user_type = action.get(
                        "user_type", DEFAULT_LOADGEN_USER_TYPE)
                    resp = requests.post(
                        f"http://{loadgen_ip}:81/api/spawn/{user_type}",
                        {
                            "user_count": int(action.get("user_count", DEFAULT_LOADGEN_USER_COUNT)),
                            "spawn_rate": int(action.get("spawn_rate", DEFAULT_LOADGEN_SPAWN_RATE)),
                            "stop_after": int(action.get("stop_after", DEFAULT_LOADGEN_TIMEOUT_SECONDS))
                        })
                    if not resp.ok:
                        raise RuntimeError(
                            f"Failed to start load generation: {resp.status_code} {resp.reason}")
            else:
                raise NotImplementedError(f"action not supported: {action}")
