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

import time
import gevent
from flask import request
from flask import jsonify
from flask import make_response
from functools import wraps
from locust.env import Environment
from locust_tasks import get_sre_recipe_user_class


def return_as_json_response(fn):
    """
    Python helper decorator for returning status code and JSON responses from
    a Flask request handler.
    """
    @wraps(fn)
    def wrapper(*args, **kwargs):
        try:
            body = fn(*args, **kwargs)
            resp = make_response(jsonify(body), 200)
            resp.headers["Content-Type"] = 'application/json'
            return resp
        except LookupError as e:
            resp = make_response(jsonify({"err": str(e)}), 404)
            resp.headers["Content-Type"] = 'application/json'
            return resp
        except ValueError as e:
            resp = make_response(jsonify({"err": str(e)}), 400)
            resp.headers["Content-Type"] = 'application/json'
            return resp
        except Exception as e:
            resp = make_response(jsonify({"err": str(e)}), 500)
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
            return {"msg": "pong"}

        @env.web_ui.app.route("/api/user_count")
        @return_as_json_response
        def user_count():
            """
            Return the number of total users spawend for load generation.

            Response:
              - user_count: int
            """
            return {"user_count": env.runner.user_count}

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
                raise ValueError(f"Must specify a valid, non-empty, integer value for query parameter 'user_count': {request.form.get('user_count', default=None)}")
            elif spawn_rate is None:
                raise ValueError(f"Must specify a valid, non-empty, integer value for query parameter 'spawn_rate': {request.form.get('spawn_rate', default=None)}")
            elif user_count <= 0:
                raise ValueError(f"Query parameter 'user_count' must be positive: {user_count}")
            elif spawn_rate <= 0:
                raise ValueError(f"Query parameter 'spawn_rate' must be positive: {spawn_rate}")
            elif user_class is None:
                raise LookupError(f"Cannot find SRE Recipe Load for: {user_identifier}")

            # Optional Query Parameters
            stop_after = request.form.get("stop_after", default=None, type=int)
            if stop_after is not None and stop_after <= 0:
                raise ValueError(f"Query parameter 'stop_after' must be positive: {stop_after}")
            elif stop_after is None and "stop_after" in request.form:
                raise ValueError(f"stop_after must be valid integer value: {request.form['stop_after']}")

            # We currently only support running one SRE Recipe load each time
            # for implementation simplicity.
            env.runner.quit()  # stop existing load generating users, if any
            env.user_classes = [user_class]  # replace with the new users

            def spawn_when_all_users_stopped():
                # Wait at most 10 seconds until all existing users are stopped, then
                # start generating new load with the new user types
                tries = 0
                while tries < 10:
                    if env.runner.user_count == 0:
                        env.runner.start(user_count, spawn_rate)
                        break
                    tries += 1
                    time.sleep(1)
                # Start anyway.
                if tries == 10:
                    env.runner.start(user_count, spawn_rate)
                # Stop later if applicable
                if stop_after:
                    gevent.spawn_later(stop_after,
                                       lambda: env.runner.quit())

            gevent.spawn(spawn_when_all_users_stopped);
            return {"msg": f"Spawn Request Received: spawning {user_count} users at {spawn_rate} users/second"}

        @env.web_ui.app.route("/api/stop", methods=['POST'])
        @return_as_json_response
        def stop_all():
            """Stop all currently running users"""
            env.runner.quit()
            return {"msg": "All users stopped"}
