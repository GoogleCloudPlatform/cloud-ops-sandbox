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

from flask import jsonify
from flask import make_response


def init_sre_recipe_web_ui(web_ui):
    """Attach custom Flask request handlers to web_ui's flask app"""
    if web_ui:
        @web_ui.app.route("/api/ping")
        def ping():
            resp = make_response(jsonify({"msg": "pong"}), 200)
            resp.headers["Content-Type"] = 'application/json'
            return resp
