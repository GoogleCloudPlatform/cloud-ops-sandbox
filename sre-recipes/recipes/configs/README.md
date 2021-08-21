# SRE Recipe Configs

This directory contains configs for supported SRE Recipes.

## Writing the Config

Each SRE Recipe config is a YAML file with the following structure

```
name: <Put the name of your recipe here. This is not user visible.>
description: <Put the description of your recipe here. This is not user visible.>
config:
  break:
    # This section lists all the shell commands to run for enabling the effects
    # of this SRE Recipe. In practice, this is where you try to break sandbox
    # services. If your SRE Recipe has complex logic, prefer running a shell
    # script here instead. You can put as many lines of `- run: ...` as needed.
    - run: <shell command>
    - run: <shell command>
  restore:
    # This section lists all the shell commands to run for disabling the effects
    # of this SRE Recipe. In practice, this is where you try to restore sandbox
    # services to its original working conditions. If your SRE Recipe has
    # complex logic, prefer running a shell script here instead.
    # You can put as many lines of `- run: ...` as needed.
    - run: <shell command>
    - run: <shell command>
  hint: <Put the hint for your recipe here.>
  verify:
    # This configures the multiple choice for asking user what service is
    # affected by this SRE Recipe.
    affected_service:
      choices:
        # Put as many answers to choose from as you need
        - <choice string 1>
        - <choice string 2>
      # The 0-based index to the correct answer in the `choices` above
      answer: 9
    # This configures the multiple choice for asking what caused the incident.
    incident_cause:
      choices:
        # Put as many answers to choose from as you need
        - <choice string 1>
        - <choice string 2>
      # The 0-based index to the correct answer in the `choices` above
      answer: 1
```

## Supported SRE Recipe Actions

The `break` and `restore` sections support the following action templates:

1. `run`: simply run the command in shell

Example:

```
- run: kubectl delete pod $(kubectl get pod -l app=frontend -o jsonpath='{.items[0].metadata.name}')
```

**Contributions**

If you want to add more pre-defined action templates, add your implementation to
the `handle_actions` method in the `RecipeRunner` class of `recipe_runner.py`.
