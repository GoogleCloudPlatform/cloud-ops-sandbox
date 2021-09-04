# Configs-Based SRE Recipe

This directory contains configs for supported config-based SRE Recipes.

## Writing the Config

Each SRE Recipe config is a YAML file with the following overall structure.

```yaml
name: <Put the name of your recipe here. This is not user visible.>
description: <Put the description of your recipe here. This is not user visible.>
config:
  # This section defines the actions to run when `sandboxctl sre-receipes break`
  # is called" . In practice, this is where you try to break sandbox services.
  #
  # If your SRE Recipe has complex logic, prefer running a shell command to
  # run a shell script instead.
  #
  # You can use, or contribute, more action templates by referring to the
  # "Supported SRE Recipe Actions" below.
  break:
    # The `run-shell-commands` action template simply runs the given shell
    # commands one at a time as it is.
    - action: run-shell-commands
      commands:
        - echo 'first command'
        - echo 'another command'

    # The `loadgen-spawn` action template will spawn the given load shape
    # producible by `user_type` (see `sre/loadgenerator/locust_tasks`) at a
    # `spawn_rate` of users per second until it reaches a total of `user_count`
    # users. The users will keep generating load until at least `stop_after`
    # seconds have passed.
    - action: loadgen-spawn
      user_type: BasicHomePageViewingUser
      user_count: 20
      spawn_rate: 5
      stop_after: 600

    # The `loadgen-stop` action template will stop any active load generation
    # produced by SRE Recipes. It is ok to call this even if there is no load
    # generation ongoing.
    - action: loadgen-stop
  # This section defines the actions to run when `sandboxctl sre-receipes restore`
  # is called". In practice, this is where you try to restore sandbox services.
  #
  # If your SRE Recipe has complex logic, prefer running a shell command to
  # run a shell script instead.
  #
  # You can use, or contribute, more action templates by referring to the
  # "Supported SRE Recipe Actions" below.
  restore:
    # The same set of action templates as `break` are supported in `restore`
    - action: run-shell-commands
      commands:
        - echo 'first command'
        - echo 'another command'
    - action: loadgen-stop
  hint: "Put the hint string for your recipe here"
  verify:
    # This configures the multiple choice for asking user what service is
    # affected by this SRE Recipe.
    affected_service:
      choices:
        # Put as many answers to choose from as you need
        - <choice string 1>
        - <choice string 2>
      answer: <The 0-based index to the correct answer in the `choices` above>
    # This configures the multiple choice for asking what caused the incident.
    incident_cause:
      choices:
        # Put as many answers to choose from as you need
        - <choice string 1>
        - <choice string 2>
      answer: <The 0-based index to the correct answer in the `choices` above>
```

## Supported SRE Recipe Actions

The `break` and `restore` sections support the following action templates:

1. `run-shell-commands`: simply run the commands one at a time in shell

Example:

```
- action: run-shell-commands
  commands:
    - kubectl delete pod $(kubectl get pod -l app=frontend -o jsonpath='{.items[0].metadata.name}')
```

2. `loadgen-stop`: stop any active load generation produced by SRE Recipes.

It is ok to call this even if there is no load generation ongoing.

Example:

```
- action: loadgen-stop
```

3. `loadgen-spawn`: start spawning the given load shape producible by
   `user_type` at a `spawn_rate` of users per second until it reaches a total of `user_count` users. The users will keep generating load until at least
   `stop_after` seconds have passed.

_Optional Parameters:_

- `user_type`: same as the `sre_recipe_user_identifier` for locust
  tasks defined in `sre/loadgenerator/locust_tasks`. You can implement new load
  shapes by contributing in `sre/loadgenerator/locust_tasks`.
  Default: `BasicHomePageViewingUser`.
- `user_count`: the number of total users to spawn. Default: `20`.
- `spawn_rate`: the number of users per second to spawn. Default: `1`.
- `stop_after`: the number of seconds to spawn before stopping. Default: `600`.

Example:

```
- action: loadgen-spawn
  user_type: BasicHomePageViewingUser
  user_count: 20
  spawn_rate: 5
  stop_after: 600
```

**Contributions**

If you want to add more pre-defined action templates, add your implementation to
the `handle_actions` method in the `RecipeRunner` class of `recipe_runner.py`.
