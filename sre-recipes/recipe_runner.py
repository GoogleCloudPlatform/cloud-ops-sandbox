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
import utils


class ConfigBasedRecipeRunner:

    def __init__(self, recipe_name):
        filepath = path.join(path.dirname(
            path.abspath(__file__)), f"recipes/configs/{recipe_name}.yaml")
        with open(filepath, "r") as file:
            self.recipe = yaml.safe_load(file.read())
        if not self.recipe:
            raise ValueError("Cannot parse config as YAML.")

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
            logging.error("Verify is not configured")
            exit(1)

        affected_service_config = verify_config.get("affected_service", {})
        if affected_service_config:
            if "answer" not in affected_service_config:
                logging.error(
                    "Correct answer is not specified for affected service quiz.")
                exit(1)
            elif "choices" not in affected_service_config:
                logging.error(
                    "No answer choices configured in affected service quiz.")
                exit(1)
            self.__run_interactive_multiple_choice(
                "Which service has an issue?",
                affected_service_config["choices"],
                affected_service_config["answer"])

        incident_cause_config = verify_config.get("incident_cause", {})
        if incident_cause_config:
            if "answer" not in incident_cause_config:
                logging.error(
                    "Correct answer is not specified for incident cause quiz.")
                exit(1)
            elif "choices" not in incident_cause_config:
                logging.error(
                    "No answer choices configured in incident cause quiz.")
                exit(1)
            self.__run_interactive_multiple_choice(
                "What was the cause of the issue?",
                incident_cause_config["choices"],
                incident_cause_config["answer"])

    ########################## Recipe Action Handlers ##########################

    def __handle_actions(self, actions):
        """
        Runs a list of `actions`, each of which is a dict of parameters.

        As of now, we only support running shell commands in the `run` field.
        Example:
            actions = [{'run': 'echo "Hello World!"'}]
        """
        if type(actions) != list:
            logging.error(
                f"Expect `actions` to be list. Found {type(actions)}: {actions}")
            exit(1)

        for action in actions:
            if type(action) != dict:
                raise ValueError(
                    f"Expect `action` to be dict. Found {type(action)}")
            logging.info(f"Runing action: {action}")
            if "run" in action:
                output, err = utils.__run_shell_command(action["run"])
                if err:
                    logging.error(f"Failed to run action {action}: {err}")
                    print(err)
                    exit(1)
            else:
                raise NotImplementedError(f"action not supported: {action}")

    def __run_interactive_multiple_choice(self, prompt, choices, correct_answer):
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
