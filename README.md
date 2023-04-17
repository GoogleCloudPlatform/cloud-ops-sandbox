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

> **Warning**
> Check [discontinued functionality](#discontinued-functionality) for the list
> of functions that are no longer supported or changed in the recent versions.

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

## Discontinued Functionality

The following functionality has been changed in the recent versions of Cloud
Ops Sandbox:

### Version 0.9.0

* Rating service is not a part of the demo application. It has the following effects:
  * Launch does not provision AppEngine services and CloudSQL DB.
  * Sandbox does not define a window-based SLO.
  * SLO recipe that uses the rating service will not be available.
* One-click installation is no longer available. Users will use `sandboxctl` CLI tool
to create and delete Sandbox. Users can leverage the walkthrough tutorial for launch
instructions.
* Starting this version, Sandbox does not create custom Cloud Shell images.
* Starting this version, launch will not create a new Google Cloud project. Users will
have to provide a project ID to host Sandbox as a parameter to CLI.
* [Website] will be retired at the end of 2023 Summer. Until that time, it will provide
a link to launch version 0.8.2 of Sandbox.
* This version uses version 0.6.0 of Online Boutique. The load generator in this version
does not expose GUI. As a result, it is not possible to customize the artificant load on
the demo application. Follow up GoogleCloudPlatform/microservices-demo#1692 to track the progress.
* SRE recipe functionality is temporary removed. Follow up #1009 to track
the progress.

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

[1]: https://console.cloud.google.com/?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fgooglecloudplatform%2Fcloud-ops-sandbox&cloudshell_tutorial=docs/walkthrough.md
[tf_badge]: https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/workflows/Terraform/badge.svg
[cloud-ops]: (https://cloud.google.com/products/operations)
[ob]: https://github.com/GoogleCloudPlatform/microservices-demo
[gke]: https://cloud.google.com/kubernetes-engine
[cli]: https://cloud.google.com/sdk/gcloud#download_and_install_the
[gke-gcloud-auth-plugin]: https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
[terraform]: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
[kubectl]: https://kubernetes.io/docs/tasks/tools/#kubectl
[here]: https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/issues/new/choose
