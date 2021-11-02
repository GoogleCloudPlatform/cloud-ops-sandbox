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

import os
import json
import yaml
import glob
import jsonschema

RECIPES_ROOT = os.path.join(os.path.dirname(
    os.path.abspath(__file__)), "../../sre-recipes/recipes/configs_based")
SCHEMA_ROOT = RECIPES_ROOT + "/schema"

print("Loading base schema...")
with open(SCHEMA_ROOT + "/schema.json", "r") as file:
    schema = json.load(file)

print("Bundling additional schema definitions...")
for def_path in glob.glob(SCHEMA_ROOT + "/defs/*.schema.json"):
    def_name = os.path.basename(def_path).split(".")[0]
    with open(def_path, "r") as def_file:
        def_schema = json.load(def_file)
    if "$defs" not in schema:
        schema["$defs"] = {}
    schema["$defs"][def_name] = def_schema

print("Running validations on all SRE recipe configs...")
has_error = False
for recipe_path in glob.glob(RECIPES_ROOT + "/*.yaml"):
    recipe_name = os.path.basename(recipe_path).split(".")[0]
    print("Validating:", recipe_name)
    with open(recipe_path, "r") as recipe_file:
        try:
            recipe_config = yaml.load(
                recipe_file.read(), Loader=yaml.FullLoader)
        except Exception as e:
            print("Invalid or empty YAML:", e)
            has_error = True
            continue
    try:
        jsonschema.validate(recipe_config, schema)
        print("Valid!")
    except Exception as e:
        print("Invalid!", e)
        has_error = True

if has_error:
    print("ERROR. At least one SRE Recipe config is invalid.")
    exit(1)
