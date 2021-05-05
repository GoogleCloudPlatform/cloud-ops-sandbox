---
title: "Cloud Monitoring"
linkTitle: "Cloud Monitoring"
weight: 70
---

{{% pageinfo %}}
* [Overview](#monitoring-overview)
* [Using Monitoring](#using-monitoring)
* [Monitoring and logs-based metrics](#monitoring-and-logs-based-metrics)
* [Creating a logs-based metric](#creating-a-logs-based-metric)
{{% /pageinfo %}}

#### Monitoring Overview

Cloud Monitoring ([documentation](https://cloud.google.com/monitoring/docs/)) is the go-to place to grasp real-time trends of the system based on SLI/. SRE team and application development team (and even business organization team) can collaborate to set up charts on the monitoring dashboard using metrics sent from the resources and the applications. 

#### Using Monitoring

To get to Cloud Monitoring from the GCP console, select **Monitoring** on the navigation panel. By default, you reach an overview page:

![image](/docs/images/user-guide/19-gcp-monitoring-overview.png)

There are many pre-built monitoring pages. For example, the GKE Cluster Details page (select **Monitoring > Dashboards > Kubernetes Engine > Infrastructure**) brings up a page that provides information about the Sandbox cluster: 

![image](/docs/images/user-guide/20-monitoring-dashboards-kubernetes.png)

You can also use the Monitoring console to create alerts and uptime checks, and to create dashboards that chart metrics you are interested in.  For example, Metrics Explorer lets you select a specific metric, configure it for charting, and then save the chart. Select **Monitoring > Metrics Explorer** from the navigation panel to bring it up.

The following chart shows the client-side RPC calls that did not result in an OK status:

![image](/docs/images/user-guide/21-metrics-explorer.png)

This chart uses the  metric type `custom.googleapis.com/opencensus/ grpc.io/client/completed_rpcs` (display name: "OpenCensus/grpc.io/client/ completed_rpcs" ), and filters on the  `grpc_client_status` label to keep only those time series  where the label's value is something other than "OK".

##### Monitoring and logs-based metrics

Cloud Logging lets you define metrics based on information in structured logs. For example, you can count the number of log entries containing a particular message or extract latency info from log records. These "logs-based metrics" can then be charted with Cloud Monitoring. For details, see ["Using logs-based metrics"](https://cloud.google.com/logging/docs/logs-based-metrics/).

Cloud Logging defines some logs-based metrics, but you can also create your own. To see the available metrics, select **Logging> Logs-based metrics** from the navigation panel. You see a summary of the system-provided and user-defined logs-based metrics:

![image](/docs/images/user-guide/22-lbms.png)

All system-defined logs-based metrics are counters.  User-defined logs-based metrics can be either counter or distribution metrics.

##### Creating a logs-based metric

To create a logs-based metric, click the **Create Metric** button at the top of the **Logs-based metrics** page or the Logs Viewer. This takes you to the Logs Viewer if needed, and also brings up the Metric Editor panel.

Creating a logs-based metric involves two general steps:

1. Identifying the set of log entries you want to use as the source of data for your entry by using the Logs Viewer. Using the Logs Viewer is briefly described in the **Cloud Logging** section of this document.
2. Describing the metric data to extract from these log entries by using the Metric Editor.

This example creates a logs-based metric that counts the number of times a user (user ID, actually) adds an item to the HipsterShop cart.  (This is an admittedly trivial example, though it could be extended. For example, from this same set of records, you can extract the user ID, item, and quantity added.)

First, create a logs query that finds the relevant set of log entries:

1. For the resource type, select **Kubernetes Container > cloud-ops-sandbox > default > server**
2. In the box with default text "Filter by label or text search", enter "AddItemAsync" (the method used to add an item to the cart), and hit return.

The Logs Viewer display shows the resulting entries:

![image](/docs/images/user-guide/23-logs.png)

Second, describe the new metric to be based on the logs query. This will be a counter metric. Enter a name and description and click **Create Metric**:

![image](/docs/images/user-guide/24-metriceditor.png)

It takes a few minutes for metric data to be collected, but once the metric collection has begun, you can chart this metric just like any other.

To chart this metric using Metrics Explorer, select **Monitoring** from the GCP console, and on the Monitoring console, select **Resources > Metrics** Explorer.

Search for the metric type using the name you gave it ("purchasing_counter_metric", in this example):

![image](/docs/images/user-guide/25-explorer.png)