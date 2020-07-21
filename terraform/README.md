Hipster Shop Terraform
================================================================================

This directory contains a heavily documented, [Terraform]
config for deploying [Hipster Shop]. It's part of the [Stackdriver Sandbox]
project. The goal of the project is to provide a one-click installer that builds
a fullly functional environment including Hipster Shop and a preconfigured 
Stackdriver environment suitable for learning and experimentation.

[Terraform]: https://www.terraform.io/
[Hipster Shop]: https://github.com/GoogleCloudPlatform/microservices-demo
[Stackdriver Sandbox]: https://stackdriver-sandbox.dev

tl;dr 
--------------------------------------------------------------------------------

* Terraform can easily provision the infrastructure necessary
* Stackdriver support in the GCP provider is limited due to
  API availability

[Cloud Graphite]: https://github.com/terraform-providers/terraform-provider-google
[GCP provider]: https://www.terraform.io/docs/providers/google/index.html

Caveats and Limitations
--------------------------------------------------------------------------------

Terraform can't deploy Kubernetes manifests directly. There are a few options,
the best of which are either generating terraform configs from the manifests or
using [Helm]. Generating configs might sound bad but it's a common pattern in the terraform community. 
All things considered, helm is probably the better option, but it requires additional
cluster setup that may or may not be reasonable to do in terraform.

[Helm]: https://helm.sh

--------------------------------------------------------------------------------

## Try it out (no script)

Make sure you have a billing account enabled.

1. [Install terraform]
2. run some commands:

```bash
$ gcloud auth application-default login
$ git clone https://source.developers.google.com/p/stackdriver-sandbox-230822/r/sandbox
$ cd sandbox/terraform
$ terraform init
$ terraform apply -var 'billing_account=<your billing account name>'
```

When this is done, you'll have a new project with a running GKE cluster, all right scopes
and APIs enabled. That's all we do right now with Terraform. 
If you want to get rid of it, run `terraform destroy`.

[Install terraform]: https://www.terraform.io/downloads.html

Guided Tour
--------------------------------------------------------------------------------

Terraform configs are split into separate files for each function. Detailed
comments are available in each file, but here's the short version:

* `00_state.tf` -- configure state storage
* `01_provider.tf` -- configure the terraform provider
* `02_project.tf` -- create a GCP project, set up billing, and enable services
* `03_gke_cluster.tf` -- provision a GKE cluster per to the Hipster Shop README

The assumption is that a system under user control would run terraform and create resources on the user's behalf. 
The user would not be aware of the underlying tool.

Monitoring Examples
--------------------------------------------------------------------------------

To provision monitoring examples for the Stackdriver Sandbox, navigate 
to the `monitoring` folder and run the command `terraform apply`. Please note that in order to run this command
you must have first created a [Monitoring Workspace] for the Google Cloud Project. 

[Monitoring Workspace]: https://cloud.google.com/monitoring/workspaces/create