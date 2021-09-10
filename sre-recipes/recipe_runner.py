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

"""
This file contains utility runtime classes implementing core SRE Recipes
features, such as breaking and restoring microservices, printing hints, and
running interactive multiple choice questions.

Currently, it implements two SRE Recipe Runner:
- ImplBasedRecipeRunner: runs SRE Recipe implemented via python classes.
- ConfigBasedRecipeRunner: runs SRE Recipes defined as YAML configs.

Refer to the class docstring for further explanations.
"""

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

    This runner will propagate all exceptions to the caller, and it is caller's
    responsibility to handle any exception and to perform any error logging.
    """

    def __init__(self, recipe_name):
        filepath = path.join(path.dirname(
            path.abspath(__file__)), f"recipes/configs_based/{recipe_name}.yaml")
        with open(filepath, "r") as file:
            self.recipe = yaml.safe_load(file.read())
        if not self.recipe:
            raise ValueError("Cannot parse config as YAML.")
        self.action_handler = ActionHandler()

    def get_name(self):
        return self.recipe.get("name", "No name found")

    def get_description(self):
        return self.recipe.get("description", "No description found")

    @property
    def config(self):
        return self.recipe.get("config", {})

    def run_break(self):
        print('Deploying broken service...')
        for action in self.config.get("break", []):
            self.action_handler.handle_action(action)
        print('Done. Deployed broken service')

    def run_restore(self):
        print('Restoring service back to normal...')
        for action in self.config.get("restore", []):
            self.action_handler.handle_action(action)
        print('Done. Restored broken service to working state.')

    def run_hint(self):
        hint = self.config.get("hint", None)
        if hint:
            print(f'Here is your hint!\n\n{hint}')
        else:
            print("This recipe has no hints.")

    def run_verify(self):
        verify_config = self.config.get("verify", [])
        if not verify_config:
            raise NotImplementedError("Verify is not configured")
        for action in verify_config:
            self.action_handler.handle_action(action)


class ActionHandler:
    """A utility helper for executing actions supported by SRE Recipe configs.

    Implementation Guide
    --------------------
    1. Map the action name to the action handler in the `__init__` method.
    2. All action handlers should take exactly one argument, which is the full 
       config specified for the action itself, as it is defined in YAML.
       For example: {action: "run-shell-commands", commands: ['echo Hi']}

    This runner will propgate all exceptions to the caller, and it is caller's
    responsibility to handle any exception and to perform any error logging.
    """

    def __init__(self):
        # Action types to action handlers
        self.action_map = {
            "run-shell-commands": self.run_shell_commands,
            "multiple-choice-quiz": self.run_multiple_choice_quiz,
            "loadgen-spawn": self.loadgen_spawn,
            "loadgen-stop": self.loadgen_stop,
        }

        # Reusable parameters shared between action handlers
        self.loadgen_ip = None

    def handle_action(self, config):
        if "action" not in config:
            raise ValueError("Action config missing `action` type")
        action_type = config["action"]
        if action_type not in self.action_map:
            raise NotImplementedError(
                f"Action type not implemented: {action_type}")
        return self.action_map[action_type](config)

    def init_loadgen_ip(self):
        if not self.loadgen_ip:
            self.loadgen_ip, err = utils.get_loadgen_ip()
            if err:
                raise RuntimeError(f"Failed to get loadgen IP: {err}")

    ############################ Action Handlers ###############################

    def run_shell_commands(self, config):
        """Runs the commands one at a time in shell.

        Config Paramters
        ----------------
        commands: string[]
            Required. A list of shell command strings.
        """
        for cmd in config["commands"]:
            output, err = utils.run_shell_command(cmd)
            if err:
                raise RuntimeError(
                    f"Failed to run command `{cmd}`: {err}")

    def run_multiple_choice_quiz(self, config):
        """Runs an interactive multiple choice quiz.

        Config Paramters
        ----------------
        prompt: string
            Required. The question prompt to display to the user.
        choices: dict[]
            option: string
                Required. The answer display text to show to the user.
            accept: bool
                Optional. If true, the choice is considered correct.
        """
        if "prompt" not in config:
            raise ValueError("No prompt specified for the multiple choice.")
        elif "choices" not in config:
            raise ValueError(
                "No answer choices available for the multiple choice.")
        utils.run_interactive_multiple_choice(
            config["prompt"], config["choices"])

    def loadgen_spawn(self, config):
        """
        Starts spawning a load shape at specified spawn rate until a total
        user count is reached. Then, stop the load after a specified timesout.

        Config Paramters
        ----------------
        user_type: string
            Optional. Same as the `sre_recipe_user_identifier` for locust tasks
            defined in `sre/loadgenerator/locust_tasks`.
            Default: BasicHomePageViewingUser.
        user_count: int
            Optional. The number of total users to spawn. Default: 20.
        spawn_rate: int
            Optional. The number of users per second to spawn. Default: 1.
        stop_after: int
            Optional. The number of seconds to spawn before stopping.
            Default: 600 seconds.
        """
        self.init_loadgen_ip()
        user_type = config.get(
            "user_type", DEFAULT_LOADGEN_USER_TYPE)
        resp = requests.post(
            f"http://{self.loadgen_ip}:81/api/spawn/{user_type}",
            {
                "user_count": int(config.get("user_count", DEFAULT_LOADGEN_USER_COUNT)),
                "spawn_rate": int(config.get("spawn_rate", DEFAULT_LOADGEN_SPAWN_RATE)),
                "stop_after": int(config.get("stop_after", DEFAULT_LOADGEN_TIMEOUT_SECONDS))
            })
        if not resp.ok:
            raise RuntimeError(
                f"Failed to start load generation: {resp.status_code} {resp.reason}")

    def loadgen_stop(self, config):
        """Stops any active load generation produced by SRE Recipes.

        Config Paramters is not required.
        """
        self.init_loadgen_ip()
        resp = requests.post(f"http://{self.loadgen_ip}:81/api/stop")
        if not resp.ok:
            raise RuntimeError(
                f"Failed to stop existing load generation: {resp.status_code} {resp.reason}")
