# the `provider` block contains the configuration for the provider, including
# credentials and region config. It can be configured via environment variables
# or via passing a path to a credentials JSON file.

# In this demo we're using Application Default Creds instead, see this for
# details: https://cloud.google.com/docs/authentication/production
#
# TODO:  we can consider configuring it via env vars
# that were populated appropriately at runtime.

provider "google" {
  # pin provider to 2.x
  version = "~> 2.1"

  # credentials = "/path/to/creds.json"
  # project = "project-id"
  # region = "default-region"
  # zone = "default-zone"
}