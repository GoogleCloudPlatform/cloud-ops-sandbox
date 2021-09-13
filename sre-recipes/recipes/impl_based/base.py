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


class BaseRecipeImpl(abc.ABC):
    """The base abstract class for implementation based SRE Recipe."""

    @abc.abstractmethod
    def get_name(self):
        """Returns the name of the recipe."""

    @abc.abstractmethod
    def get_description(self):
        """Returns the descripion of the recipe."""

    @abc.abstractmethod
    def run_break(self):
        """Performs SRE Recipe actions to break a sandbox service."""

    @abc.abstractmethod
    def run_restore(self):
        """Performs SRE Recipe actions to restore a sandbox service."""

    @abc.abstractmethod
    def run_hint(self):
        """Prints a hint about the root cause of the issue"""

    @abc.abstractmethod
    def run_verify(self):
        """
        Verifies that the user of the recipe found the correct impacted broken
        service, as well as the root cause of the breakage."""
