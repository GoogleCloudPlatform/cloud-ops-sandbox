# ![](docs/images/coud-ops-icon.png =24x24) Cloud Operations Sandbox

![Terraform][tf_badge]

Cloud Operations (Ops) Sandbox is an end-to-end demo that helps practitioners to
learn about [Cloud Operations][cloud-ops] (formerly Stackdriver) and Service
Reliability Engineering practices from Google.

Sandbox is composed of the [Online Boutique][ob] microservice demo application
and a collection of various observability instruments. It offers:

* Study running a microservice application on [GKE]
* Monitor application's behavior using various system and application metrics
displayed on per-service dashboards
* Explore Uptime checks, Service SLOs and other instruments of Cloud Operations
suite of Google Cloud
* Experiment with created observability instruments and build new ones
* Run quick labs using Sandbox Recipes (🚧 _temporary unavailable_)

## Using Cloud Ops Sandbox

Cloud Ops Sandbox runs on Google Cloud.
To use it you will need a Google Cloud account with an access to create a new
GCP project or to provision resource on the existing GCP project.

### Launch

You can launch Cloud Ops Sandbox using Cloud Shell button below and following
walkthrough instructions:

[![Launch in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)][1]

Or, you can launch it on your workstation. To run it locally you will need to
make sure that the following software is available:

* [Google Cloud CLI][cli] with [gke-gcloud-auth-plugin]
* [Terraform]
* [kubectl]
* curl
* sed

And to have a Google Cloud project where you want to launch Cloud Ops Sandbox.
After that, run the following commands while replacing `PROJECT_ID` with your
project ID:

```bash
git clone https://github.com/GoogleCloudPlatform/cloud-ops-sandbox
gcloud auth application-default loging
cloud-ops-sandbox/provisioning/sandboxctl create -p PROJECT_ID
```

These commands will clone this repo to your local environment's current directory,
acquire authentication toke for Terraform and launch Cloud Ops Sandbox with default
settings. The script will prompt you for additional information.

You can learn more about customized options by running:

```bash
cloud-ops-sandbox/provisioning/sandboxctl -h
```

### Use Cloud Ops Sandbox

Read more about Cloud Ops Sandbox and how to use it in the [documentation](docs/README.md).

## Code of Conduct

Please see the [code of conduct](CODE_OF_CONDUCT.md)

## Contributions

Please see the [contributing guidelines](CONTRIBUTING.md)

## License

This product and Online Boutique application, its code and assets are licensed
under Apache 2.0. Full license text is available in [LICENSE](LICENSE).

---

> **Note**
> This is not an official Google project. Please, report any issues or feature requests related to this project [here].

[1]: (https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fgooglecloudplatform%2Fcloud-ops-sandbox&cloudshell_tutorial=docs/walkthrough.md&cloudshell_workspace=.)
[tf_badge]: https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/workflows/Terraform/badge.svg
[cloud-ops]: (https://cloud.google.com/products/operations)
[ob]: https://github.com/GoogleCloudPlatform/microservices-demo
[gke]: https://cloud.google.com/kubernetes-engine
[cli]: https://cloud.google.com/sdk/gcloud#download_and_install_the
[gke-gcloud-auth-plugin]: https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
[terraform]: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
[kubectl]: https://kubernetes.io/docs/tasks/tools/#kubectl
[here]: https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/issues/new/choose
