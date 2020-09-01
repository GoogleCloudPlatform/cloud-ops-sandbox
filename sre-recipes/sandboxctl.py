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
This CLI is the interface for sre recipes. It deploys and rolls back
broken services as well as verifies that the user found the correct
cause of the broken service.

For information on how to run the CLI, run the following:
`python3 sandboxctl.py --help`
"""

import os
from pkgutil import iter_modules
from pathlib import Path
from importlib import import_module
from inspect import isclass
import click
from recipe import Recipe


def get_recipes():
    """
    Gets all valid recipes in sre-recipes/recipes, and returns
    the recipe names
    """
    recipes = {}
    recipes_root_dir = os.path.dirname(os.path.abspath(__file__)) + '/recipes'
    recipes_root_modules_path = Path(recipes_root_dir).resolve()
    for (_, recipe_module_name, _) in iter_modules([recipes_root_modules_path]):
        recipe_module_path = Path(recipes_root_dir + '/' + recipe_module_name).resolve()
        for (_, recipe_name, _) in iter_modules([recipe_module_path]):
            recipe_module = import_module('.'.join(['recipes', recipe_module_name, recipe_name]))
            for attribute_name in dir(recipe_module):
                attribute = getattr(recipe_module, attribute_name)
                if isclass(attribute) and attribute is not Recipe \
                    and issubclass(attribute, Recipe):
                    globals()[attribute_name] = attribute
                    try:
                        recipe_obj = attribute()
                        recipes[attribute_name] = recipe_obj
                    except TypeError:
                        pass
    return recipes


RECIPES = get_recipes()
@click.command()
@click.argument('action', type=click.Choice(['break', 'restore', 'verify']))
@click.argument('recipe_name', type=click.Choice(RECIPES.keys()))
def main(action, recipe_name):
    """Performs an action on a recipe."""
    recipe = RECIPES[recipe_name]
    if action == 'break':
        recipe.break_service()
    elif action == 'restore':
        recipe.restore_service()
    elif action == 'verify':
        recipe.verify()


if __name__ == "__main__":
    main()
