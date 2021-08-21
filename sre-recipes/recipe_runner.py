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


class RecipeRunner:

    def __init__(self, recipe_name):
        filepath = path.join(path.dirname(
            path.abspath(__file__)), f"recipes/configs/{recipe_name}.yaml")
        with open(filepath, "r") as file:
            self.recipe = yaml.safe_load(file.read())

    @property
    def name(self):
        return self.recipe.get("name", "No name found")

    @property
    def description(self):
        return self.recipe.get("description", "No description found")

    @property
    def config(self):
        return self.recipe.get("config", {})

    ############################ Run Recipe ###################################

    def run_break(self):
        print('Deploying broken service...')
        self.__run_steps(self.config.get("break", {}))
        print('Done. Deployed broken service')

    def run_restore(self):
        print('Restoring broken service...')
        self.__run_steps(self.config.get("restore", {}))
        print('Done. Restored broken service to working state.')

    def run_hint(self):
        hint = self.config.get("hint", "This recipe has no hints.")
        print(f'Here is your hint!\n\n{hint}')

    def run_verify(self):
        raise NotImplementedError()

    ########################## Recipe Action Handlers ##########################

    def __run_shell_command(self, command, decode_output=True):
        """
        Runs the given command and returns any output and error
        If `decode_output` is True, try to decode output with UTF-8 encoding,
        as well as removing any single quote.
        """
        process = subprocess.Popen(
            command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True
        )
        output, error = process.communicate()
        if output is not None and decode_output:
            output = output.decode("utf-8").replace("'", '').strip()
        return output, error

    def __run_steps(self, steps):
        if type(steps) != list:
            logging.error(
                f"Expect `steps` to be list. Found {type(steps)}: {steps}")
            exit(1)
        elif not steps:
            logging.error("There are no steps configured.")
            exit(1)

        for step in steps:
            if type(step) != dict:
                raise ValueError(
                    f"Expect `step` to be dict. Found {type(step)}")
            logging.info(f"Runing step: {step}")
            if "run" in step:
                output, err = self.__run_shell_command(step["run"])
                if err:
                    logging.error(f"Failed to run step {step}: {err}")
                    exit(1)
            else:
                raise NotImplementedError(f"Step not supported: {step}")


# runner = RecipeRunner("recipe1")
# # print(runner.config)
# # print(utils.get_project_id())
# print(runner.name)
# print(runner.description)
# # print(runner.break_config)
# # print(runner.restore_config)
# runner.run_hint()
# # print(runner.verify_config)
# runner.run_break()
# runner.run_restore()
