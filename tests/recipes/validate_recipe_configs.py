import os
import json
import yaml
import glob
import jsonschema

RECIPES_ROOT = os.path.join(os.path.dirname(
    os.path.abspath(__file__)), "../../sre-recipes/recipes/configs_based")
SCHEMA_ROOT = f"{RECIPES_ROOT}/schema"

print("Loading base schema...")
with open(f"{SCHEMA_ROOT}/schema.json", "r") as file:
    schema = json.load(file)

print("Bundling additional schema definitions...")
for def_path in glob.glob(f"{SCHEMA_ROOT}/defs/*.schema.json"):
    def_name = os.path.basename(def_path).split(".")[0]
    with open(def_path, "r") as def_file:
        def_schema = json.load(def_file)
    if "$defs" not in schema:
        schema["$defs"] = {}
    schema["$defs"][def_name] = def_schema

print("Running validations on all SRE recipe configs...")
has_error = False
for recipe_path in glob.glob(f"{RECIPES_ROOT}/*.yaml"):
    recipe_name = os.path.basename(recipe_path).split(".")[0]
    print(f"Validating {recipe_name}")
    with open(recipe_path, "r") as recipe_file:
        try:
            recipe_config = yaml.load(
                recipe_file.read(), Loader=yaml.FullLoader)
        except Exception as e:
            print(f"Invalid or empty YAML: {e}")
            has_error = True
            continue
    try:
        jsonschema.validate(recipe_config, schema)
        print(f"{recipe_name} is valid!")
    except Exception as e:
        print(f"{recipe_name} failed validation!\n {e}")
        has_error = True

if has_error:
    print("ERROR. At least one SRE Recipe config is invalid.")
    exit(1)
