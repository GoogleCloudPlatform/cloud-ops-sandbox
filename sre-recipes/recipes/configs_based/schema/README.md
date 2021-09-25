## Config Based SRE Recipe Schema

This directory defines the schema validation for SRE Recipes configs.

It uses the JSON Schema (https://json-schema.org/) definition based the parsed
JSON from the YAML format.

### Usage

If you need to write reusable schema definitions that can be referenced via
`$ref` field, define them in the `./defs` subdirectory.

### Adding validation for a new SRE Recipe action

1. Define the JSON schema for your action config under `./defs`.

   For example, our `loadgen-spawn` action config schema validation are defined
   at `./defs/loadgen-spawn.schema.json`

2. Add your new action to the `./defs/action-config-list.schema.json` schema

   a. Add your action config name to the list of `enums` under `Supported action configs names`.

   b. Attach your schema definition reference to the config name by adding a new `if-then` tuple under `allOf`.

For example, if you added a new action handler for `action: my-action`, then:

1. create a `./defs/my-action.schema.json` schema definition
2. add to the `action-config-list.schema.json`:

```
{
  // other stuff ....
  "items": {
    "properties": {
      "action": {
        "type": "string",
        "description": "Supported action configs names",
        "enum": [
          // other stuff ....
          "my-action" // step a: add your action name here
        ]
      }
    },
    "allOf": [
      // ....
      // step b: attach your schema definition here
      {
        "description": "The schema definition for `action: my-action`",
        "if": {
          "properties": { "action": { "const": "my-action" } }
        },
        "then": {
          "$ref": "#/$defs/my-action"
        }
      }
    ]
  },
  // other stuff ....
}
```
