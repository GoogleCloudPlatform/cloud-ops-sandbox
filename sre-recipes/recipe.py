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
This module contains an abstract base class that defines the required
behavior of each recipe.
"""

import abc

class Recipe(abc.ABC):
    """
    This abstract base class outlines the required behavior of a recipe.
    """

    @abc.abstractmethod
    def break_service(self):
        """Deploys the broken service"""

    @abc.abstractmethod
    def restore_service(self):
        """Restores working condition"""

    @abc.abstractmethod
    def verify(self):
        """
        Verifies that the user of the recipe found the root cause
        of the breakage
        """
    