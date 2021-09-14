# Implementation-Based SRE Recipe

This directory contains configs for implementation based SRE Recipes.

## Implementing the Recipe

To create a implemented base SRE Recipe, create a file under `recipes/impl_based`
directory that implements a child class extending the `BaseRecipeImpl` from
`base.py`.

For the recipe to be recognized as a recipe runnable via `sandboxctl`, include
`recipe` substring somewhere in the filename

For example, to implement a recipe named `my_recipe` that can be invoked via
`sandboxctl sre-recipes <action> my_recipe`, create a python implementation
named `recipes/impl_based/my_recipe.py` that implements a child class
extending the `BaseRecipeImpl` from `base.py`.

If you are curious about how our SRE Recipe runner loads and reads your
implementation dynamically, check out the `ImplBasedRecipeRunner` in
`recipe_runner.py`.
