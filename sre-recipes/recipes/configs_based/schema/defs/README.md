# JSON Schema Definitions

This directory contains all the JSON schema definitions that will be pulled into
the root `$def` section of the main root schema at `schema.json` (in the parent
directory) for reference at SRE Recipe validation schema bundling time.

**Requirements**

1. All schema definitions should follow the naming convention of `ABC.schema.json`
2. The individual schema definition file should NOT define its own `definitions`
   or `$defs` sections. If you need to reuse certain schema definition, make
   it a new schema definition file on its own.

For a definition file named `ABC.schema.json`, it can be referenced by
`#/$defs/abc` by both the root `schema.json` and any other definition file
under this `./defs` directory.

### Example

- `schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "schema.json",
  "type": "object",
  "properties": {
    "first-name": {
      "$ref": "#/$defs/name"
    },
    "last-name": {
      "$ref": "#/$defs/name"
    },
    "age": {
      "$ref": "#/$defs/age"
    }
  }
}
```

- `defs/name.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "name.schema.json",
  "type": "string",
  "minLength": 1
}
```

- `defs/age.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "age.schema.json",
  "type": "integer",
  "minimum": 1
}
```
