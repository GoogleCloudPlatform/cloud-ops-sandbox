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

# -*- coding: utf-8 -*-
"""
This module contains the implementation of a dummy implementation based Recipe.
"""

from .base import BaseRecipeImpl


class DummyRecipe(BaseRecipeImpl):

    def get_name(self):
        return "A dummy recipe"

    def get_description(self):
        return "A implementation based recipe for illustration purposes only"

    def run_break(self):
        print("Nothing to break.")

    def run_restore(self):
        print("Nothing to restore.")

    def run_hint(self):
        print("No hints needed. I am a dummy recipe.")

    def run_verify(self):
        print("Nothing to verify. It's just a dummy recipe")
