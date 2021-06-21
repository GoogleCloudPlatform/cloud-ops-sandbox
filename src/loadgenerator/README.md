# Load Generator

The Load Generator is implemented in [Locust](https://github.com/locustio/locust)
in library mode.

## Load Shapes ("Locust Tasks")

The Locust tasks that specify how to generate loads and traffic pattern to a
target endpoint are implemented in `locust_tasks` package. You can learn more
about how they work [here](https://docs.locust.io/en/stable/writing-a-locustfile.html).

All the load tasks can be imported with function helpers defined in the `locust_tasks/__init__.py`.

## SRE Recipe Endpoint

The `locust_tasks/sre_recipe_load_tasks.py` is a special file containing load tasks used by
SRE Recipes for simulating specific load when certain SRE Recipes are triggered.
You can read more about SRE Recipes in the root `sre-recipes` directory of this
project.

Specifically, this load generator implementation exposes the client facing load
generator via the `80` port, and a new, independent, hidden load generator
backend at `81` port to be triggered only by SRE Recipes for separation of
concerns.

The `81` port SRE Recipe Load Generation endpoints implemented so far include:

- `GET /api/ping`: ping the api for health
- `POST /api/spawn/<user_identifier>`: spawn a Locust load generating user
  by `user_identifier` at `spawn_rate` users per second, for a total of
  `user_count` users. An optional form parameter `stop_after` can be set to
  automatically stop all load generating users after a certain number of seconds
  has passed.
- `GET /api/user_count`: return the current number of users currently spawned
  and are generating loads.
- `POST/api/stop`: stop all load generating users

Additional endpoints exposed natively by Locust are still available. Please
refer to the [official Locust documentation](https://docs.locust.io/en/stable/index.html)
for details.

### Extensions

The SRE Recipe API endpoint for load generation is implemented in Flask. You can
add more request handlers in `sre_recipe_utils.py` with `init_sre_recipe_api`
function. It supports any request handlers supported by [Flask](https://flask.palletsprojects.com/en/1.1.x/quickstart/).
