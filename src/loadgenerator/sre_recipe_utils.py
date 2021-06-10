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
"""
This module contains code for intergrating SRE Recipes with LoadGen
"""

import gevent
from flask import request
from flask import jsonify
from flask import make_response
from functools import wraps
from locust.env import Environment
from locust_tasks import get_sre_recipe_user_class

WAIT_SECONDS_BEFORE_SPAWN = 2


def return_as_json_response(fn):
    """
    Python helper decorator for returning status code and JSON responses from
    a Flask request handler.
    """
    @wraps(fn)
    def wrapper(*args, **kwargs):
        status_code, body = fn(*args, **kwargs)
        resp = make_response(jsonify(body), status_code)
        resp.headers["Content-Type"] = 'application/json'
        return resp
    return wrapper


def init_sre_recipe_api(env):
    """
    Attach custom Flask request handlers to a locust environment's flask app
    """
    if env and env.web_ui:
        @env.web_ui.app.route("/api/ping")
        @return_as_json_response
        def ping():
            return 200, {"msg": "pong"}

        @env.web_ui.app.route("/api/user_count")
        @return_as_json_response
        def user_count():
            """
            Return the number of total users spawend for load generation.

            Response:
              - user_count: int
            """
            return 200, {"user_count": env.runner.user_count}

        @env.web_ui.app.route("/api/spawn/<user_identifier>", methods=['POST'])
        @return_as_json_response
        def spawn_by_user_identifier(user_identifier=None):
            """
            Spawn a number of users with the SRE Recipe user identifer.

            Form Paramters:
            - user_count: Required. The total number of users to spawn
            - spawn_rate: Required. The spawn rate for the users.
            - stop_after: Optional. If specified, run the load generation only 
                          for the given number of seconds.

            Response:
              On success, returns status code 200 and an acknowledgement 'msg'
              On error, returns status code 400 for invalid arguments, and 404
              if load pattern for 'user_identifier' is not found, as well as an
              'err' message.
            """
            # Required Query Parameters
            user_count = request.form.get("user_count", default=None, type=int)
            spawn_rate = request.form.get("spawn_rate", default=None, type=int)
            # The function returns None, if user_identifier is not found
            user_class = get_sre_recipe_user_class(user_identifier)
            

            if user_count is None:
                return 400, {"err": f"Must specify a valid, non-empty, integer value for query parameter 'user_count': {user_count}"}
            elif spawn_rate is None:
                return 400, {"err": f"Must specify a valid, non-empty, integer value for query parameter 'spawn_rate': {spawn_rate}"}
            elif user_count <= 0:
                return 400, {"err": f"Query parameter 'user_count' must be positive: {user_count}"}
            elif spawn_rate <= 0:
                return 400, {"err": f"Query parameter 'spawn_rate' must be positive: {spawn_rate}"}
            elif user_class is None:
                return 404, {"err": f"Cannot find SRE Recipe Load for: {user_identifier}"}

            # Optional Query Parameters
            stop_after = request.form.get("stop_after", default=None, type=int)
            if stop_after is not None and stop_after <= 0:
                return 400, {"err": f"Query parameter 'stop_after' must be positive: {stop_after}"}

            # We currently only support running one SRE Recipe load each time
            # for implementation simplicity.
            env.runner.quit()  # stop existing load generating users, if any
            env.user_classes = [user_class]  # replace with the new users

            # wait a short while for all existing users to stop, then
            # start generating new load with the new user types
            gevent.spawn_later(WAIT_SECONDS_BEFORE_SPAWN,
                               lambda: env.runner.start(user_count, spawn_rate))

            if stop_after:
                gevent.spawn_later(WAIT_SECONDS_BEFORE_SPAWN + stop_after,
                                   lambda: env.runner.quit())

            return 200, {"msg": f"Spawn Request Received: spawning {user_count} users at {spawn_rate} users/second"}

        @env.web_ui.app.route("/api/stop", methods=['POST'])
        @return_as_json_response
        def stop_all():
            """Stop all currently running users"""
            env.runner.quit()
            return 200, {"msg": "All users stopped"}
