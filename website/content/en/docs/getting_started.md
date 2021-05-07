---
title: "Getting Started"
linkTitle: "Getting Started"
weight: 2
---
{{% pageinfo %}}
* [Using Sandbox](#using-sandbox)
  * [Prerequisites](#prerequisites)
  * [Set Up](#set-up)
  * [Next Steps](#next-steps)
  * [Clean Up](#clean-up)
* [Service Overview](/docs/service_overview/)
  * [Screenshots](/docs/service_overview/#screenshots)
  * [Architecture](/docs/service_overview/#service-architecture)
  * [Technologies](/docs/service_overview/#technologies)
{{% /pageinfo %}}

## Using Sandbox

### Prerequisites

* Create and enable [Cloud Billing Account](https://cloud.google.com/billing/docs/how-to/manage-billing-account).

### Set Up

Click the Cloud Shell button for automated one-click installation of a new Sandbox cluster in a new Google Cloud Project.

[![Open in Cloud Shell](http://www.gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/cloud-ops-sandbox.git&cloudshell_git_branch=v0.5.0&shellonly=true&cloudshell_image=gcr.io/stackdriver-sandbox-230822/cloudshell-image/uncertified:v0.5.0&cloudshell_tutorial=docs/tutorial.md)

__Note__: If installation stops due to billing account errors, set up the billing account and type: `sandboxctl create`.

### Next Steps

* Explore your Sandbox deployment and its [architecture](#Service-Overview)
* Follow the User Guide to start using [Cloud Operations](https://cloud-ops-sandbox.dev/docs/user-guide/learn-cloud-learn-cloud-operations/)
* Learn more about Cloud Operations using [Code Labs](https://codelabs.developers.google.com/s/results?q=Monitoring)

### SRE Recipes

SRE Recipes is our [Chaos Engineering](https://en.wikipedia.org/wiki/Chaos_engineering) tool to test your sandbox environment. It helps users to familiarize themselves with finding the root cause of a breakage using Cloud Operations suite of tools.  
Each 'recipe' simulates a different scenario of real life problems that can occur to the production system. There are several recipes that you can run and you can also [contribute your own.](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/sre-recipes#contributing)  

```
$ sandboxctl sre-recipes  
```

#### Running an example SRE Recipe

> **Note:** Recipe's names are not explicit by design as we don't want to allude to the problem.

1. Run the recipe to manufacture errors in the demo cluster

> **Note:** It may take up to 5 minutes for breakages to take effect in production.
```
$ sandboxctl sre-recipes break recipe0
```

2. Use Cloud Operations suite to diagnose the problem.

> **Note:** If you are stuck, you can use a hint to direct you to the right direction.
```
$ sandboxctl sre-recipes hint recipe0
```

3. Verify your hypothesis on what could be wrong with the demo app by using command line tool

```
$ sandboxctl sre-recipes verify recipe0
```

4. After you discover the problem, you can restore the cluster to its original state.

```
$ sandboxctl sre-recipes restore recipe0
```

### Clean Up

When you are done using Cloud Operations Sandbox, you can tear down the environment by deleting the GCP project that was set up for you. This can be accomplished in any of the following ways:

* Use the `sandboxctl` script:

```bash
sandboxctl destroy
```

* If you no longer have the Cloud Operations Sandbox files downloaded, delete your project manually using `gcloud`

```bash
gcloud projects delete $YOUR_PROJECT_ID
```

* Delete your project through Google Cloud Console's [Resource Manager web interface](https://console.cloud.google.com/cloud-resource-manager)

## For Developers

If you are a developer and want to contribute to the Sandbox, you can refer to [CONTIBUTING.md](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/blob/master/CONTRIBUTING.md).

---

This is not an official Google project.
