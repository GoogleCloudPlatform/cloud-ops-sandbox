# Here we configure the state backend. For this demo we're using the "local"
# backend which stores everything in a local directory. The config you see below
# is functionally equivalent to the defaults... in actual use you'd either omit
# this stanza or configure it differently.

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# In a productized version of this, we'd probably store state remotely on a
# per-instance basis. In that case we'd generate a backend config just before
# running terraform that would look something like this:

# terraform {
#   backend "gcs" {
#     bucket = "stackdriver-sandbox"
#     prefix = "<project-id>"
#   }
# }

# Interpolations are not supported in backend configs so we'd have to generate
# the file rather than rely on env vars like we can do almost everywhere else.
