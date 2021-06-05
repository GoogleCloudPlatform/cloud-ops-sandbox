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
import utils
import logging
import yaml


class RecipeRunner:

    def __init__(self, recipe_name):
        filepath = path.join(path.dirname(
            path.abspath(__file__)), "configs", f"{recipe_name}.yaml")
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

    @property
    def hint(self):
        return self.config.get("hint", "This recipe has no hints.")

    ############################ Run Recipe ###################################

    def run_break(self):
        print('Deploying broken service...')
        self.handle_actions(self.config.get("break", []))
        print('Done. Deployed broken service')

    def run_restore(self):
        print('Restoring broken service...')
        self.handle_actions(self.config.get("restore", []))
        print('Done. Restored broken service to working state.')

    def run_hint(self):
        print(f'Here is your hint!\n\n{self.hint}')

    def run_verify(self):
        raise NotImplementedError()

    ########################## Recipe Action Handlers ##########################

    def handle_actions(self, actions):
        for action in actions:
            action_type = action.get("type", None)
            if action_type == 'set_env_variable':
                self.handle_set_env_variable(action)
            elif action_type == 'update_gcloud_scheduler':
                self.handle_update_gcloud_scheduler(action)
            else:
                logging.error(
                    f"Unimplemented action '{action_type}' found in '{self.name}'")
                exit(1)

    def handle_set_env_variable(self, action):
        for field in ["service", "selector", "feature_flag", "feature_value"]:
            if field not in action:
                logging.error(
                    f"Can't run set_env_variable. Missing '{field}' flag in config")
                exit(1)

        utils.set_env_vars(
            action["service"],
            f'{action["feature_flag"]}={action["feature_value"]}')

        pod_name, _ = utils.get_pod_name_by_selector(
            action["selector"])
        if not pod_name:
            logging.error(
                f"Can't run set_env_variable. Failed to get pod name")
            exit(1)

        utils.delete_pod_by_name(pod_name)
        utils.wait_for_service(
            action["service"], action.get("restart_wait_seconds", 600),
            condition="available")

    def handle_update_gcloud_scheduler(self, action):
        raise NotImplementedError()


runner = RecipeRunner("recipe0")
# print(runner.config)
# print(utils.get_project_id())
print(runner.name)
print(runner.description)
# print(runner.break_config)
# print(runner.restore_config)
runner.run_hint()
# print(runner.verify_config)
# print(runner.run_break())
# print(runner.run_restore())
