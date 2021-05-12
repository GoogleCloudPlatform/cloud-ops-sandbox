# Cloud Operations Sandbox Tutorial

## Overview

The Cloud Operations Sandbox is intended to make it easy for you to deploy and run a non-trivial application that lets you explore the Google Cloud Platform services, particularly the [Cloud Operations](http://cloud.google.com/products/operations) (formerly Stackdriver) product suite. Cloud Operations is a suite of tools that helps you gain full observability into your code and applications.

The Hipster Shop application used in the sandbox is intended to be sufficiently complex such that you can meaningfully experiment with it, and the Sandbox automatically provisions a new demo cluster, configures and deploys Hipster Shop, and simulates real users.

With the Sandbox running, you can experiment with various Cloud Operations tools to solve problems and accomplish standard SRE tasks in a sandboxed environment without impacting your production monitoring setup.

### Architecture of the Hipster Shop application

The Hipster Shop application consists of a number of microservices, written in a variety of languages, that talk to each other over gRPC. [To learn more.](https://cloud-ops-sandbox.dev/docs/service_overview/#service-architecture)

### Prerequisites

You must have an active Google Cloud Platform Billing Account. If you already have one, you can skip this section.

Otherwise, to create a GCP Billing Account, do the following:

1. Go to the Google Cloud Platform [Console](https://console.cloud.google.com/) and sign in (if you have an account), or sign up (if you don't have an account).
1. Select **Billing** from the navigation panel and follow the instructions.

For more information, see ["Create a new billing account"](https://cloud.google.com/billing/docs/how-to/manage-billing-account).

## Set up

The installation process takes a few minutes. When it completes, you see a message like the following:

```bash
Cloud Operations Sandbox deployed successfully!
    Google Cloud Console GKE Dashboard: https://console.cloud.google.com/kubernetes/workload?project=<project_ID>
    Google Cloud Console Monitoring Workspace: https://console.cloud.google.com/monitoring?project=<project_ID>
    Hipstershop web app address: http://XX.XX.XX.XX
    Load generator web interface: http://XX.XX.XX.XX
```

The URLs in this message tell you where to find the results of the installation.

If a message does **not** appear, and the installation script is not able to run, then try running `sandboxctl create` in your Cloud Shell terminal once you have set-up your billing account.

### Recovering from session timeout
Should your Cloud Shell session timeout due to user inactivity, you will need to launch the custom Cloud Shell image to access the `sandboxctl` command.
Click the

![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.png)

button from the [Cloud Operations Sandbox homepage](https://cloud-ops-sandbox.dev/) to restart the custom Cloud Shell.

## Explore the Sandbox!

Cloud Operations Sandbox comes with several capabilities out-of-the-box, in this tutorial, we walk through a guided tour of products in Cloud Operations and explore how they can be used to work with an application.
For additional information please refer to the [User Guide](https://cloud-ops-sandbox.dev/docs/).

Let's get started!

### Explore your project in GCP

In another browser tab, navigate to the GCP GKE Dashboard URL, which takes you to the [Kubernetes Engine **Workloads** page](https://console.cloud.google.com/kubernetes/workload) for the project created by the installer ([documentation](https://cloud.google.com/kubernetes-engine/docs/)).

### Shop like a hipster!

In a new browser tab, navigate to the Hipster Shop URL, where you can "purchase" everything you need for your hipster lifestyle using a mock credit card number.

### Run the load generator

Cloud Ops Sandbox comes with [Locust load generator](https://locust.io/), to simulate users traffic.  

- In another browser tab, navigate to the load-generator URL(from the installation stage if it isn't populated).  
- Enter the number of **users** and **spawn rate**. For this application, we recommend to test 100 total users with a spawn rate of 2 users per second.  
- Fill in the **Host** field with the "Hipster shop web address" from the installation stage if it isn't populated.  
- Click the **Start swarming** button to begin generating traffic to the site.

From here, you can explore how the application was deployed, and you can use the navigation menu to bring up other GCP tools.

### Explore Cloud Monitoring

Navigate to the GCP Monitoring Workspace URL, which takes you to the [Cloud Monitoring **Workspace** page](https://console.cloud.google.com/monitoring) for your new project. The console may take some time to create a new workspace. Afterward, you'll be able to see a few dashboards generated through Cloud Operations tools.

## Learn Cloud Operations 

### Cloud Operations Overview

Cloud Operations provides products for both developers and administrators, this section introduces a few of the products, for additional information refer to the [User Guide.](https://cloud-ops-sandbox.dev/docs/)

Application developers need to be able to investigate the cause of problems in applications running in distributed environments, and in this context, the importance of **Application Performance Management (APM)** has increased. Cloud Operations provides 3 products for APM:

-  [Cloud Trace](https://console.cloud.google.com/traces)
-  [Cloud Profiler](https://console.cloud.google.com/profiler)
-  [Cloud Debugger](https://console.cloud.google.com/debug)

> Note: The recommended solution for application instrumentation is [**OpenCensus**](https://opencensus.io/), an open-source project that supports trace instrumentation in a variety of languages and that can export this data to Cloud.

Similarly, cloud-native, microservice-based applications complicate traditional approaches used by administrators for monitoring system health: it's harder to observe your system health when the number of instances is flexible and the inter-dependencies among the many components are complicated. In the last few years, **Site Reliability Engineering (SRE)** has become recognized as a practical approach to managing large-scale, highly complex, distributed systems. 
In addition, Cloud Operations provides the several tools that are useful for [Site Reliability Engineering (SRE)](https://sre.google/):

-  [Cloud Monitoring](https://console.cloud.google.com/monitoring)
-  [Cloud Logging](https://console.cloud.google.com/logs)
-  [Cloud Error Reporting](https://console.cloud.google.com/errors)


## The Cloud Observability Products: Monitoring, Logging, and Error Reporting

Next, learn about Cloud Observability products!

### Cloud Monitoring

[Cloud Monitoring](https://console.cloud.google.com/monitoring) is the go-to place to grasp real-time trends of the system based on SLI/SLO. SRE team and application development team (and even business organization team) can collaborate to set up charts on the monitoring dashboard using metrics sent from the resources and the applications. 

#### Using Monitoring

To get to Cloud Monitoring from the GCP console, select **Monitoring** on the navigation panel. By default, you reach an overview page.

There are many pre-built monitoring pages. For example, the GKE Cluster Details page (select **Monitoring > Dashboards > Kubernetes Engine > Infrastructure**) brings up a page that provides information about the Sandbox cluster.

You can also use the Monitoring console to create alerts and uptime checks, and to create dashboards that chart metrics you are interested in.  For example, Metrics Explorer lets you select a specific metric, configure it for charting, and then save the chart. Select **Monitoring > Metrics Explorer** from the navigation panel to bring it up.

### Monitoring and logs-based metrics

Cloud Logging defines some logs-based metrics, but you can also create your own, for details, see ["Using logs-based metrics"](https://cloud.google.com/logging/docs/logs-based-metrics/).. To see the available metrics, select **Logging> Logs-based metrics** from the navigation panel. You see a summary of the system-provided and user-defined logs-based metrics.

> Note: All system-defined logs-based metrics are counters.  User-defined logs-based metrics can be either counter or distribution metrics.

### Creating a logs-based metric

To create a logs-based metric, click the **Create Metric** button at the top of the **Logs-based metrics** page or the Logs Viewer. This takes you to the Logs Viewer if needed, and also brings up the Metric Editor panel.

Creating a logs-based metric involves two general steps:

1. Identifying the set of log entries you want to use as the source of data for your entry by using the Logs Viewer. Using the Logs Viewer is briefly described in the **Cloud Logging** section of this document.
2. Describing the metric data to extract from these log entries by using the Metric Editor.

This example creates a logs-based metric that counts the number of times a user (user ID, actually) adds an item to the HipsterShop cart.  (This is an admittedly trivial example, though it could be extended. For example, from this same set of records, you can extract the user ID, item, and quantity added.)

First, create a logs query that finds the relevant set of log entries:

1. For the resource type, select **Kubernetes Container > cloud-ops-sandbox > default > server**
2. In the box with default text "Filter by label or text search", enter "AddItemAsync" (the method used to add an item to the cart), and hit return.

Second, describe the new metric to be based on the logs query. This will be a counter metric. Enter a name and description and click **Create Metric**.

It takes a few minutes for metric data to be collected, but once the metric collection has begun, you can chart this metric just like any other.

To chart this metric using Metrics Explorer, select **Monitoring** from the GCP console, and on the Monitoring console, select **Resources > Metrics** Explorer.

Search for the metric type using the name you gave it.

## Cloud Logging

Operators can look at [logs](https://console.cloud.google.com/logs) in [Cloud Logging](https://cloud.google.com/logging/docs/) to find clues explaining any anomalies in the metrics charts. 

### Using Logging

You can access Cloud Logging by selecting **Logging** from the GCP navigation menu. This brings up the Logs Viewer interface.

The Logs Viewer allows you to view logs emitted by resources in the project using search filters provided.  The Logs Viewer lets you select standard filters from pulldown menus. 

### An example: server logs

To view all container logs emitted by pods running in the default namespace, use the Resources and Logs filter fields (these default to **Audited Resources** and **All logs**):

1. For the resource type, select **GKE Container -> cloud-ops-sandbox -> default**
2. For the log type,  select **server**

The Logs Viewer now displays  the logs generated by pods running in the default namespace.

For additional information and examples like log export see [User Guide.](https://cloud-ops-sandbox.dev/docs/user-guide/learn-ops-management/cloud_logging/)  

## Cloud Error Reporting

[Cloud Error Reporting](https://console.cloud.google.com/errors) ([documentation](https://cloud.google.com/error-reporting/docs/)) automatically groups errors depending on stack trace message patterns and shows the frequency of each error group. The error groups are generated automatically, based on stack traces.
On opening an error group report, operators can access to the exact line in the application code where the error occurred and reason about the cause by navigating to the line of the source code on Google Cloud Source Repository. 

### Using Error Reporting

You can access Error Reporting by selecting **Error Reporting** from the GCP navigation menu.

> **Note:** Error Reporting can also let you know when new errors are received; see ["Notifications for Error Reporting"](https://cloud.google.com/error-reporting/docs/notifications) for details.

To get started, select any open error by clicking on the error in the **Error** field.

The **Error Details** screen shows you when the error has been occurring in the timeline and provides the stack trace that was captured with the error.  **Scroll down** to see samples of the error.

Click **View Logs** for one of the samples to see the log messages that match this particular error.

You can expand any of the messages that matches the filter to see the full stack trace.

## SLO Monitoring

Cloud operations sandbox comes with several predefined SLOs(Service level objectives), that allow us to measure our users happiness. To learn more about SLIs and SLOs [visit here.](https://cloud.google.com/blog/products/devops-sre/sre-fundamentals-slis-slas-and-slos)

Cloud operations suite provides **service oriented monitoring**, that means that we are configuring SLIs, SLOs and Burning Rates Alerts for a 'service'. Cloud Operations Sandbox' services are already detected since Istio automatically detects and creates services for us. But to demonstrate that you can create your own services, it also deploys custom services using [Terraform](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/terraform/monitoring).

You can find all the services under [monitoring → services → Services Overview](https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring/ui/svc-overview) , and you can create your own [custom service.](https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring/ui/define-svc)

![image](./images/user-guide/37-services-overview.png)  

### Services SLOs  

To view, edit or create SLOs for a service you need to go to the service page, for additional information refer to the [User Guide.](https://cloud-ops-sandbox.dev/docs/)
> The *predefined SLOs* are also deployed as part of [Terraform code](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/terraform/monitoring/04_slos.tf) and currently are for the mentioned custom services, the Istio service and Rating service.  

![Services example](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/raw/master/docs/images/user-guide/37-services-overview.png "Example of Cloud Operations Services")

### Configure your own SLIs and SLOs

You can [configure your own SLIs and SLOs](https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring/ui/create-slo) for an existing service or for your own custom service.  

> **Remember**  Our scope to examine and measure our users' happiness is User journey, so in order to create the SLO you need to identify the most important ones to the business. Then we want to *identify the metrics* that are closest to the customer experience and ingest that data.  

1. In the service screen we will choose Create SLO
2. Then we will set our SLI, we need to choose SLI type and the method(request vs window based)
3. Then we wil define our metric and we can also preview its performance based on historical data
4. Then we will configure our SLO, our target in a specific time window. We can also choose between [rolling window or a calendar window](https://sre.google/workbook/implementing-slos/)

### Configure Burn Rate Alerts

After you created the SLO, you can create [Burn Rate Alerts](https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate) for those.

> There are also several *predefined polices* are deployed as part of [Terraform](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/blob/master/terraform/monitoring/05_alerting_policies.tf). You can view or edit them in the service screen.

5. In the service screen we will be able to see our new SLO and we will choose 'Create Alerting Policy'
6. Then we will want to set the alert's condition, who and how they will be notified and additional instructions
7. After it will be created you could see it and incidents that might be triggered due to it in teh service screen and in the Alerting screen

For additional information refer to the [User Guide.](https://cloud-ops-sandbox.dev/docs/user-guide)

## SRE Recipes

SRE Recipes is our [Chaos Engineering](https://en.wikipedia.org/wiki/Chaos_engineering) tool to test your sandbox environment. It helps users to familiarize themselves with finding the root cause of a breakage using Cloud Operations suite of tools.  
Each 'recipe' simulates a different scenario of real life problems that can occur to the production system. There are several recipes that you can run and you can also [contribute your own.](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/sre-recipes#contributing)  

```
$ sandboxctl sre-recipes  
```

### Running an example SRE Recipe

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

## Destroying your cluster

Once you have finished exploring the Cloud Operations Sandbox project, don't forget to destroy it to avoid incurring additional billing.

Destroy your Sandbox project by opening the Cloud Shell and running sandboxctl destroy:
```
$ sandboxctl destroy
```

**Note:** This script destroys the current project. If `sandboxctl create` were run again, a Sandbox project with a new project id would be created.

### Congratulations on finishing the Cloud Operations Sandbox tutorial!
