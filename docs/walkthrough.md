# Cloud Ops Sandbox Walkthrough

## Introduction

Cloud Ops Sandbox is intended to make it easy for you to explore observability
capabilities of Google Cloud services on the example of a non-trivial
microservice architecture deployed on Kubernetes.
[Cloud Operations][1] suite (formerly known as Stackdriver) is a collection of
services and tools that helps you gain full observability into your workloads.

Cloud Ops Sandbox uses [Online Boutique][2] OSS as the example application.
When launched, Cloud Ops Sandbox provisions a GKE cluster and deploys Online
Boutique services together with an opinionated configuration of Cloud
Operations suite that includes monitoring dashboards, uptime checks, service
SLOs and alerts.

You can experiment with Cloud Ops Sandbox environment to simulate problems with
Online Boutique services and to use Cloud Operations services and tools to
observe and troubleshoot the problems.

Cloud Ops Sandbox uses Terraform to provision and configure necessary resources
and tools.

Estimated time
<walkthrough-tutorial-duration duration="15"></walkthrough-tutorial-duration>
<walkthrough-tutorial-difficulty difficulty="1"></walkthrough-tutorial-difficulty>

## Project Setup

Before you begin, you will need a Google Cloud project.
Do the following steps to create or select the project that will be used to
launch Cloud Ops Sandbox and to enable required Google Cloud APIs.

**Note:** It is highly recommended to use a project that is dedicated to
launch Cloud Ops Sandbox. Using the same project to host other applications
may result in unexpected decrease in performance or other conflicts.

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

Configure Cloud Shell to use the selected project by running the following
command in Cloud Shell:

```bash
gcloud configure set project <walkthrough-project-id/>
```

<walkthrough-enable-apis apis=
   "container.googleapis.com,
   cloudprofiler.googleapis.com">
</walkthrough-enable-apis>

If prompted, authorize Cloud Shell to call listed Google Cloud APIs.

## Launch Cloud Ops Sandbox

To launch Sandbox using default settings run the following command in Cloud Shell:

```shell
provisioning/sandboxctl create --project-id <walkthrough-project-id/>
```

By default the launch will install [Anthos Service Mesh][3](ASM) and the
load generator that will create a simulated load on the demo application.
Also it will provision the [regional cluster][4] in the `us-central1` region.
If you wish to customize any of these default settings, you will need to run the
above command with additional parameters.

By default the launch will run all Online Boutique services in [ASM][3].
If you are not interested in using ASM, add the `--skip-asm` parameter to the
launch command.

If you want to experiment with Sandbox without simulated load, add the
`--skip-loadgenerator` parameter to the launch command below.

In order to change the region where GKE cluster is provisioned or to be provisioned
it as a [zonal cluster][5], add `--cluster-location [LOC]` parameter.
And provide a name of a region or a zone as `[LOC]`

The GKE cluster name is set to `cloud-ops-sandbox`. If you want to customize it
add `--cluster-name [NAME]` parameter to the launch command below while
replacing `[NAME]` with the desired legal cluster name.

During launch process, CLI prints out execution log (mainly from Terraform) to
console. On completion, you should see the output similar to the following:

```terminal
Explore Cloud Ops Sandbox features by browsing

GKE Dashboard: https://console.cloud.google.com/kubernetes/workload?project=<walkthrough-project-id/>
Monitoring Workspace: https://console.cloud.google.com/monitoring/?project=<walkthrough-project-id/>
Trying Online Boutique at http://10.0.0.1/
```

You can use these URL to explore GKE cluster and Sandbox observability artifacts.

### Recovering from errors

If the launch fails due interim connection issues, repeat the launch command to
restart the process.
If the problem persists, use CLI to [delete Sandbox](#delete-launched-sandbox)
in order to clean up the failed launch and then try the launch process again.

## Explore the Sandbox

After completing launch process you can experiment with various Sandbox components.
If you are not ready to explore, click **Next** button to learn about how to
delete the launched Sandbox.

### Explore Online Boutique

Start with exploring the Online Boutique application that Sandbox uses.

Open the Cloud Console navigation menu, hover over Kubernetes Engine,
and then click Services & Ingress.

<walkthrough-menu-navigation sectionId="KUBERNETES_SECTION;discovery"></walkthrough-menu-navigation>

In the list shown list of services, look for the service of **Type** `External
load balancer`. The service name will be "istio-gateway" if you launched
Sandbox with ASM or "frontend-external" if you launched it without ASM.
In the endpoint column of this service, click the link with trailing `:80`.
A browser will open a window with Online Boutique application. You can
experiment with it to see what workflows can be triggered by user's actions.

### Explore Cloud Trace

You can see follow these workflow traces in Cloud Trace.
Open the Cloud Console navigation menu, hover over Trace,
and then click Trace List.

<walkthrough-menu-navigation sectionId="TRACES_SECTION;trace_list"></walkthrough-menu-navigation>

You will see all traces reported by Online Boutique services.
Try to select any of them to get more information about call stack.

**Note:** There can be not enough information immediately after launch.
You may want to return to this screen later.

You can also check Overview screen for trace statistics of the project.
To do it, click on Overview menu in the toolbar on the left.

<walkthrough-spotlight-pointer locator="semantic({link 'Overview, 1 of 3'})"></walkthrough-spotlight-pointer>

## Delete Launched Sandbox

When you do not need Cloud Ops Sandbox anylonger, don't forget to delete it to
avoid incurring additional costs.

To delete the launched Sandbox, run the following command:

```bash
provisioning/sandboxctl delete --project-id <walkthrough-project-id/>
```

**Warning:** If you customized your launch with additional parameters
(e.g. custom location), you will need to use these parameters for delete
operations. Otherwise, the delete operation may fail.

If you launched Sandbox in a dedicated project and do not need the project,
you can simply [shut down the project][6].

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

[1]: http://cloud.google.com/products/operations
[2]: https://github.com/GoogleCloudPlatform/microservices-demo
[3]: https://cloud.google.com/anthos/service-mesh
[4]: https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters#regional_clusters
[5]: https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters#zonal_clusters
[6]: https://cloud.google.com/resource-manager/docs/creating-managing-projects#shutting_down_projects
