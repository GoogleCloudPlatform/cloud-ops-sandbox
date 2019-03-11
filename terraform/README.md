Hipster Shop Terraform PoC
================================================================================

This directory contains a heavily documented, proof-of-concept level [Terraform]
config for deploying [Hipster Shop]. It's part of the [Stackdriver Sandbox]
project. The goal of the project is to provide a one-click installer that builds
a fullly functional environment including Hipster Shop, some new tools and
services, and a preconfigured Stackdriver environment suitable for learning and
experimentation.

[Terraform]: https://www.terraform.io/
[Hipster Shop]: https://github.com/GoogleCloudPlatform/microservices-demo
[Stackdriver Sandbox]: https://docs.google.com/document/d/1mz7VfgQN8Yi6-4H25FrQu6z8LeZfWJksd-cvgeD26A8/edit

⚠️ This should not be shared publicly! ⚠️

tl;dr:
--------------------------------------------------------------------------------

IMO, at this point (1-Feb-2019) terraform does not provide significant value
over what we could accomplish with a shell script. This will remain true until
we can manage the desired Stackdriver resources with terraform, which will
require the APIs to reach beta and [Cloud Graphite] to add support for them to
the [GCP provider].

More details below, but in a nutshell:

* Terraform can easily provision the infrastructure necessary
* Some heroics are required to deploy Hipster Shop
* Stackdriver support in the GCP provider is limited, possibly/probably due to
  API availability

[Cloud Graphite]: http://go/cloud-graphite/projects/terraform.md
[GCP provider]: https://www.terraform.io/docs/providers/google/index.html

Caveats and Limitations
--------------------------------------------------------------------------------

The most significant issue is that right now we can't do much configuration of
Stackdriver with terraform. There's limited support for Logging and Monitoring
but that's all. My understanding is that there are additional APIs under
development. Once those APIs are available we could in theory start adding
support to the terraform provider, but we'd have to do it ourselves. Cloud
Graphite's policy is to only build support for beta or GA APIs.

A secondary issue is that terraform can't deploy Kubernetes manifests
directly. There are a few options, the best of which are either generating
terraform configs from the manifests or using [Helm]. Generating configs might
sound bad but it's a common pattern in the terraform community. All things
considered, helm is probably the better option, but it requires additional
cluster setup that may or may not be reasonable to do in terraform.

[Helm]: https://helm.sh

Okay but I want to try it anyway
--------------------------------------------------------------------------------

[![Open in Cloud Shell](//gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://source.developers.google.com/p/stackdriver-sandbox-230822/r/sandbox&cloudshell_git_branch=terraform-demo&cloudshell_working_dir=terraform)

That's cool! I'm not going to stop you.First, make sure you have a billing
account called "Google". Capitalization matters. Ideally that billing account is
owned by your @google.com GCP user and has your external user listed as an
administrator.

1. [Install terraform]
2. run some commands:

```
$ gcloud auth application-default login
$ git clone -b terraform-demo https://source.developers.google.com/p/stackdriver-sandbox-230822/r/sandbox
$ cd sandbox/terraform
$ terraform init
$ terraform apply -var 'billing_account=<your billing account name>'
```

3. there is no step three! Unless you count the commands as separate steps.

When this is done, you'll have a new project with a running GKE cluster. That's
all we can do right now. If you want to get rid of it, run `terraform destroy`.

[Install terraform]: https://www.terraform.io/downloads.html

Guided Tour
--------------------------------------------------------------------------------

I've split the terraform configs into separate files for each function. Detailed
comments are available in each file, but here's the short version:

* `00_state.tf` -- configure state storage
* `01_provider.tf` -- configure the terraform provider
* `02_project.tf` -- create a GCP project, set up billing, and enable services
* `03_gke_cluster.tf` -- provision a GKE cluster per to the Hipster Shop README

I've tried to call out the places where changes would be necessary to productize
this. Those cases are all based on the assumption that a system under our
control would run terraform and create resources on the user's behalf. The user
would not be aware of the underlying tool.

I did not consider the scenario where we ship these configs to the user to
execute themselves.
