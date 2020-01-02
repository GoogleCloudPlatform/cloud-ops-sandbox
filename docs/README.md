# Stackdriver Sandbox User Guide

# Overview

The Stackdriver Sandbox is intended to make it easy for you to deploy and run a non-trivial application that lets you explore the Google Cloud Platform services and the [Stackdriver](http://cloud.google.com/stackdriver) product suite. Stackdriver is a suite of tools that helps you gain full observability into your code and applications.

The Hipster Shop application used in the sandbox is intended to be sufficiently complex such that you can meaningfully experiment with it, and the Sandbox automatically provisions a new demo cluster, configures and deploys Hipster Shop, and simulates real users.

With the Sandbox running, you can experiment with various Stackdriver tools to solve problems and accomplish standard SRE tasks in a sandboxed environment without impacting your production monitoring setup.

## Architecture of the Hipster Shop application

The Hipster Shop application consists of a number of microservices, written in a variety of languages, that talk to each other over gRPC.

![image](./images/user-guide/1-architecture.png)

**Note:** We are not endorsing this architecture as the best way to build a real online store. This application is optimized for demonstration and learning purposes.  It illustrates a large number of cloud-native technologies, uses a variety of programming languages, and provides an environment that can be explored productively with Stackdriver tools.

The Git repository you cloned has all the source code, so you can explore the implementation details of the application. See the repository [README](https://github.com/GoogleCloudPlatform/stackdriver-sandbox) for a guided tour.

# Prerequisites

You must have an active Google Cloud Platform Billing Account. If you already have one, you can skip this section.

Otherwise, to create a GCP Billing Account, do the following:

1. Go to the Google Cloud Platform [Console](https://console.cloud.google.com/) and sign in (if you have an account), or sign up (if you don't have an account).
1. Select **Billing** from the navigation panel and follow the instructions.

For more information, see ["Create a new billing account"](https://cloud.google.com/billing/docs/how-to/manage-billing-account).

# Set up

## Deploy the Sandbox

In a new browser tab, navigate to the Stackdriver Sandbox [website] (https://stackdriver-sandbox.dev/) and follow the instructions there:

1. Click the **Open in Google Cloud Shell** button. You might have to click Proceed on a second dialog if you haven't run Cloud Shell before.

After the shell starts, the Stackdriver Sandbox repository is cloned to your shell container, and you are placed in the `stackdriver-sandbox/terraform` directory.

2. Run the installer script:

```
$ ./install.sh
```

The `install.sh` script performs the following tasks:

-  Enables the necessary GCP features
-  Creates a GCP project named "Stackdriver Sandbox Demo"
-  Creates and configures a GKE cluster and deploys the microservices that make up the Hipster Shop application
-  Starts a Compute Engine instance and runs [Locust](https://locust.io/), a load-generator application

The installation process takes a few minutes. When it completes, you see a message like the following:

```bash
********************************************************************************
Stackdriver Sandbox deployed successfully!

     Stackdriver Dashboard: https://app.google.stackdriver.com/accounts/create
     Google Cloud Console Dashboard: https://console.cloud.google.com/kubernetes/workload?project=stackdriver-sandbox-68291054
     Hipstershop web app address: http://35.202.126.83
     Load generator web interface: http://34.68.50.4:8080
```

The URLs in this message tell you where to find the results of the installation:

-  The **Stackdriver Dashboard URL** is where you will end up when you go to Stackdriver Monitoring from the GCP console. The GCP project created by the installer must be part of a Workspace in Stackdriver Monitoring.  A Workspace ([documentation](https://cloud.google.com/monitoring/workspaces/)) is a Stackdriver concept for organizing multiple GCP projects.

> A Workspace will be created automatically for your project if you don't have one already, so you don't have to do anything explicitly with this URL.

-  The **Google Cloud Console** **Dashboard** URL takes you to the Kubernetes Engine console for your deployment.

-  The **Hipster Shop** URL takes you to the storefront.

-  The **load generator** URL takes you to an interface for generating synthetic traffic to Hipster Shop.

## Shop like a hipster!

In a new browser tab, navigate to the Hipster Shop URL, where you can "purchase" everything you need for your hipster lifestyle using a mock credit card number:

![image](./images/user-guide/2-hipstershop.png)

## Run the load generator

In another browser tab, navigate to the load-generator URL, from which you can simulate users interacting with the application to generate traffic. For this application, values like 100 users with a "hatch rate" of 2 (spawn 2 users per second) are reasonable.

![image](./images/user-guide/3-locust.png)

## Explore your project in GCP

In another browser tab, navigate to the GCP Dashboard URL, which takes you to the Kubernetes Engine (_[documentation_](https://cloud.google.com/kubernetes-engine/docs/)) **Workloads** page for the project created by the installer:

![image](https://drive.google.com/a/google.com/file/d/1gMk2tNv7GHJcbnEKjA_MoEC4bOJG35G3/view?usp=drivesdk)

From here, you can explore how the application was deployed, and you can use the  
navigation menu to bring up other GCP tools, including Stackdriver.

# Learn Stackdriver

## Stackdriver Overview

As the cloud-native microservice architecture, which promises scalability and flexibility benefits, gets more popular, developers and administrators need tools that can work across cloud-based distributed systems.

Stackdriver provides products for both developers and administrators; this section introduces the products and their general audiences.  The tools are covered in more detail later.

Application developers need to be able to investigate the cause of problems in applications running in distributed environments, and in this context, the importance of** Application Performance Management (APM)** has increased. Stackdriver provides 3 products for APM:

-  Stackdriver Trace
-  Stackdriver Profiler
-  Stackdriver Debugger

Similarly, cloud-native, microservice-based applications complicate traditional approaches used by administrators for monitoring system health: it's harder to observe your system health when the number of instances is flexible and the inter-dependencies among the many components are complicated. In the last few years, **Site Reliability Engineering (SRE)** has become recognized as a practical approach to managing large-scale, highly complex, distributed systems. Stackdriver provides the following tools that are useful for SRE:

-  Stackdriver Monitoring
-  Stackdriver Logging
-  Stackdriver Error Reporting

You can find the Stackdriver products in the navigation panel on the GCP Console:

![image](https://drive.google.com/a/google.com/file/d/1Uf7rNl1KrJhbkyGel2BAh1NEaFBOgvMf/view?usp=drivesdk)

## The Stackdriver APM products: Trace, Profiler, and Debugger

### Stackdriver Trace

#### Trace Overview

Stackdriver Trace (_[documentation_](https://cloud.google.com/trace/docs/)) enables developers to see distributed traces that visually expose latency bottleneck in requests. Developers instrument application code to collect trace information. You can also include environmental information in traces and trace information can be included in Stackdriver Logging logs. The Trace UI can then pull relevant log events into the trace timelines. 

For instrumenting your applications, currently recommended solution is **OpenCensus.** [OpenCensus](https://opencensus.io/) is an open-source project that supports trace instrumentation in a variety of languages and that can export this data to Stackdriver. Then you can use the Stackdriver Trace UI to analyze the data. Note that OpenCensus is merging with another similar project, OpenTracing, to form OpenTelemetry. See **_[OpenCensus to become OpenTelemetry**_](#heading=h.5pjkrlyqlz9e)  in this doc.

HipsterShop microservices are instrumented to collect trace data. In addition to distributed tracing, **OpenCensus (Stats)** provides the sink to send quantifiable data, such as database latency, open file descriptors, and so on, that helps to set up monitoring of [SLIs and SLOs](https://cloud.google.com/blog/products/gcp/sre-fundamentals-slis-slas-and-slos) for the service. This data is available in Stackdriver Monitoring, and HipsterShop microservices are also instrumented to collect this kind of data.

#### Using Trace

To bring up Stackdriver Trace, click **Trace** in the GCP navigation panel. This takes you to the Trace **Overview** page, where you see the traces generated by the Sandbox microservices:

![image](https://drive.google.com/a/google.com/file/d/1cDx-JC6yDw_X5vqCebJlzZCHjl2dBzcu/view?usp=drivesdk)

Click **Trace List **in the navigation panel to get the list of traces captured during a particular time:

![image](https://drive.google.com/a/google.com/file/d/1Q63lfe1WGlXxqyaUdAWbjkd0_K_YnctP/view?usp=drivesdk)

Click on any trace in the timeline to get a detailed view and breakdown of the traced call and the subsequent calls that were made:

![image](https://drive.google.com/a/google.com/file/d/18IW8uc0t2O9yqOuHqH335bKzf8Dea9zz/view?usp=drivesdk)

Finally, click **Analysis Reports **in the navigation menu to see a list of reports that are generated: 

![image](https://drive.google.com/a/google.com/file/d/1E8snuHR8w0QqE7LMo6i1iqjyDUW6Jn2w/view?usp=drivesdk)

> **Note**:  if you have just set up the Sandbox environment, you may not have any reports; click on **Create a report** to create one.

View one of the reports that was created (or the one you created yourself) to understand either the density or cumulative distribution of latency for the call you selected:

![image](https://drive.google.com/a/google.com/file/d/1TJZUxeSl2Ojg4BJ4LQYmpZ4wWl_J-ixX/view?usp=drivesdk)

Feel free to explore the tracing data collected from here before moving on to the next section.

### Stackdriver Profiler

#### Profiler Overview

Stackdriver Profiler _([documentation_](https://cloud.google.com/profiler/docs/)) performs statistical sampling on your running application. Depending on the language, it can capture statistical data on CPU utilization, heap size, threads, and so on. You can use the charts created by the Profiler UI to help identify performance bottlenecks in your application code. 

You do not have to write any profiling code in your application; you simply need to make the Profiler library available (the mechanism varies by language). This library will sample performance traits and create reports, which you can then analyze with the Profiler UI.

The following Hipster Shop microservices are configured to capture profiling data:

-  Checkout service
-  Currency service
-  Frontend
-  Payment service
-  Product-catalog service
-  Shipping service

#### Using Profiler

Select **Profiler** from the GCP navigation menu to open the Profiler home page. It comes up with a default configuration and shows you the profiling graph:

![image](https://drive.google.com/a/google.com/file/d/1sTOmjM9aK6FCL1WE_Y2txVlEeJEGIBDZ/view?usp=drivesdk)

You can change the service, the profile type, and many other aspects of the configuration For example, to select the service you'd like to view Profiler data for, choose a different entry on the **Service** pulldown menu:

![image](https://drive.google.com/a/google.com/file/d/1y9iKwKNaoBfq_b9bLr05hjJVUR_uMevU/view?usp=drivesdk)

Depending on the service you select and the language it's written in, you can select from multiple metrics collected by Profiler:

![image](https://drive.google.com/a/google.com/file/d/1Qa6GZT156fI97A-EMXDskIF-Tp0w_9JW/view?usp=drivesdk)

See ["Types of profiling available"](https://cloud.google.com/profiler/docs/concepts-profiling#types_of_profiling_available) for information on the specific metrics available for each language.

Profiler uses a visualization called a flame graph to represents both code execution and resource utilization. See ["Flame graphs"](https://cloud.google.com/profiler/docs/concepts-flame) for information on how to interpret this visualization. You can read more about how to use the flame graph to understand your service's efficiency and performance in  ["Using the Profiler interface"](https://cloud.google.com/profiler/docs/using-profiler#profiler-graph).

### Stackdriver Debugger

#### Debugger Overview

You might have experienced situations where you see problems in production environments but they can't be reproduced in test environments. To find a root cause, then, you need to step into the source code or add more logs of the application as it runs in the production environment. Typically, this would require re-deploying the app, with all associated risks for production deployment.

Stackdriver Debugger (_[documentation_](https://cloud.google.com/debugger/docs/)) lets developers debug running code with live request data. You can set breakpoints and log points on the fly. When a breakpoint is hit, a snapshot of the process state is taken, so you can examine what caused the problem. With log points, you can add a log statement to a running app without re-deploying, and without incurring meaningful performance costs.

You do not have to  add any instrumentation code to your application to use Stackdriver Debugger. You start the debugger agent in the container running the application, and  you can then use the Debugger UI to step through snapshots of the running code.

The following Hipster Shop microservices are configured to capture debugger data:

-  Currency service
-  Email service
-  Payment service
-  Recommendation service

#### Using Debugger

undefinedTo bring up the Debugger, select **Debugger** from the navigation panel on the GPC console:

![image](https://drive.google.com/a/google.com/file/d/1qgjTW3rDR6SX_hSA8Gb-kzG_k7DUSM3g/view?usp=drivesdk)

As you can see, Debugger requires access to source code to function.  For this exercise, you'll download the code locally and link it to Debugger.

##### Download source code

In **Cloud Shell**, issue these **commands** to download a release of the Sandbox source code and extract the archive:

```
cd ~
wget https://github.com/GoogleCloudPlatform/stackdriver-sandbox/archive/next19.tar.gz
tar -xvf next19.tar.gz
cd stackdriver-sandbox-next19
```

##### Create and configure source repository

To create a Cloud Source Repository for the source code and to configure Git access, issue these commands in Cloud Shell:

```
gcloud source repos create google-source-captures
git config --global user.email "user@domain.tld" # substitute with your email
git config --global user.name "first last"       # substitute with your name
```

##### Upload source code to Debugger

In the Debugger home page, **copy** the command (_don't click the button!_) in the "Upload a source code capture to Google servers" box, but **_don't include the `LOCAL_PATH` variable**_. (You will replace this with another value before executing the command.)

![image](https://drive.google.com/a/google.com/file/d/1uq-0USjiBxSP7NKe0nQg_7h1V958t6LI/view?usp=drivesdk)

Paste the command into your Cloud Shell prompt and add a space and a period:

```
gcloud beta debug source upload --project=stackdriver-sandbox-68291054 --branch=6412930C2492B84D99F3 .
```

Enter _RETURN_ to execute the command.

In the Debugger home page, click the **Select Source** button under "Upload a source code capture" option, which will then open the source code:

![image](https://drive.google.com/a/google.com/file/d/1a7fIzZn0BipqSkWJbOVmgBRJoToKxS_n/view?usp=drivesdk)

You are now ready to debug your code!

##### Create a snapshot

Start by using the Snapshot functionality to understand the state of your variables.  In the Source capture tree, open the **`server.js`** file under **src** > **currencyservice.** 

Next, click on** line 121** to create a snapshot. in a few moments, you should see a snapshot be created, and you can view the values of all variables at that point on the right side of the screen:

![image](https://drive.google.com/a/google.com/file/d/1nUoX-_4yV86PdTk-s911TE2z9HNN4VkC/view?usp=drivesdk)

#### 

undefined##### Create a logpoint

Switch to the **Logpoint** tab on the right side. To create the logpoint:

1. Again, click on **line 121** of **`server.js`** to position the logpoint.
1. In the **Message** field, type "testing logpoint" to set the message that will be logged.
1. Click the **Add** button. 

To see all messages that are being generated in Stackdriver Logging from your logpoint, click the **Logs** tab in the middle of the UI. This brings up an embedded viewer for the logs:

![image](https://drive.google.com/a/google.com/file/d/1hRQfAXhXCcg-AME5S6Zdp-IVCXvwDGe8/view?usp=drivesdk)

## The Stackdriver observability products:Monitoring, Logging, and Error Reporting

### Stackdriver Monitoring

#### Monitoring Overview

Stackdriver Monitoring ([documentation](https://cloud.google.com/monitoring/docs/)) is the go-to place to grasp real-time trends of the system based on SLI/SLO. SRE team and application development team (and even business organization team) can collaborate to set up charts on the monitoring dashboard using metrics sent from the resources and the applications. 

#### Using Monitoring

To get to Stackdriver Monitoring from the GCP console, select **Monitoring** on the navigation panel. This brings up the Stackdriver Monitoring console, a separate UI from the consoles for other GCP and Stackdriver products.  By default, you reach an overview page:

![image](https://drive.google.com/a/google.com/file/d/14SPZJ6JcxM87SQcTPsmzjklHqVsqs5jR/view?usp=drivesdk)

undefinedThere are many pre-built monitoring pages. For example, the GKE Cluster Details page (select** Resources > (Infrastructure) Kubernetes Engine**) brings up a page that provides information about the Sandbox cluster:

![image](https://drive.google.com/a/google.com/file/d/1gDOBETXZw5PUCwAr7oE2jsW-UGVqObBu/view?usp=drivesdk)

undefinedYou can also use the Monitoring console to create alerts and uptime checks, and to create dashboards that chart metrics you are interested in.  For example, Metrics Explorer lets you select a specific metric, configure it for charting, and then save the chart. Select **Resources > Metrics Explorer** to bring it up.

The following chart shows the client-side RPC calls that did not result in an OK status:

![image](https://drive.google.com/a/google.com/file/d/1c5YsBwCe-RsxdLs06Am5dwd_5kNVaqnS/view?usp=drivesdk)

This chart uses the  metric type `custom.googleapis.com/opencensus/ grpc.io/client/completed_rpcs` (display name: "OpenCensus/grpc.io/client/ completed_rpcs" ), and filters on the  `grpc_client_status` label to keep only those time series  where the label's value is something other than "OK".

undefined

##### Monitoring and logs-based metrics

Stackdriver Logging lets you define metrics based on information in structured logs. For example, you can count the number of log entries containing a particular message or extract latency info from log records. These "logs-based metrics" can then be charted with Stackdriver Monitoring. For details, see ["Using logs-based metrics"](https://cloud.google.com/logging/docs/logs-based-metrics/).

Stackdriver Logging defines some logs-based metrics, but you can also create your own. To see the available metrics, select **Logging> Logs-based metrics** from the navigation panel. You see a summary of the system-provided and user-defined logs-based metrics:

![image](https://drive.google.com/a/google.com/file/d/19vO0MJFvea6cY81DF3iTkTa165iA8Dnz/view?usp=drivesdk)

All system-defined logs-based metrics are counters.  User-defined logs-based metrics can be either counter or distribution metrics

undefined##### 

##### Creating a logs-based metric

To create a logs-based metric, click the **Create Metric** button at the top of the **Logs-based metrics** page or the Logs Viewer. This takes you to the Logs Viewer if needed, and also brings up the Metric Editor panel.

Creating a logs-based metric involves two general steps:

1. Identifying the set of log entries you want to use as the source of data for your entry by using the Logs Viewer. Using the Logs Viewer is briefly described in the**_ [Stackdriver Logging**_](#heading=h.7ne7r81t60uh) section of this document.
1. Describing the metric data to extract from these log entries by using the Metric Editor.

This example creates a logs-based metric that counts the number of times a user (user ID, actually) adds an item to the HipsterShop cart.  (This is an admittedly trivial example, though it could be extended. For example, from this same set of records, you can extract the user ID, item, and quantity added.)

First, create a logs query that finds the relevant set of log entries:

1. For the resource type, select **GKE Container -> stackdriver-sandbox -> default**
1. For the log type,  select **server**
1. In the box with default text "Filter by label or text search", enter "AddItemAsync" (the method used to add an item to the cart), and hit return.

The Logs Viewer display shows the resulting entries:

![image](https://drive.google.com/a/google.com/file/d/1wjWPv4Ope5TCX0ZcvDpRRkdMwTKgKDkp/view?usp=drivesdk)

undefined##### 

Second, describe the new metric to be based on the logs query. This will be a counter metric. Enter a name and description and click **Create Metric**:

![image](https://drive.google.com/a/google.com/file/d/1XXWBJVkELTZG343o6q4LRefozFYFHP-N/view?usp=drivesdk)

It takes a few minutes for metric data to be collected, but once the metric collection has begun, you can chart this metric just like any other.

undefined

To chart this metric using Metrics Explorer, select **Monitoring** from the GCP console, and on the Monitoring console, select **Resources > Metrics** Explorer.

Search for the metric type using the name you gave it ("purchasing_counter_metric", in this example):

![image](https://drive.google.com/a/google.com/file/d/1dTjBqVyeaS-1YBKTqldiuqh2zSBe3T11/view?usp=drivesdk)

### Stackdriver Logging

#### Logging Overview

On detecting unusual symptoms in the charts, operators can look into Stackdriver Logging (_[documentation_](https://cloud.google.com/logging/docs/)) to find clues of it in the log messages. Filtering lets you identify relevant logs, and logs can be exported from Stackdriver Logging to "sinks" for long-term storage.

#### Using Logging

You can access Stackdriver Logging by selecting **Logging** from the GCP navigation menu. This brings up the Logs Viewer interface:

![image](https://drive.google.com/a/google.com/file/d/1b0ZLzUJ6dYZ7ZyHYDfjAoJFDzyc7nmSk/view?usp=drivesdk)

The Logs Viewer allows you to view logs emitted by resources in the project using search filters provided.  The Logs Viewer lets you select standard filters from pulldown menus. 

##### An example: server logs

To view all container logs emitted by pods running in the default namespace, use the Resources and Logs filter fields (these default to **Audited Resources** and **All logs**):

1. For the resource type, select **GKE Container -> stackdriver-sandbox -> default**
1. For the log type,  select **server**

The Logs Viewer now displays  the logs generated by pods running in the default namespace:

![image](https://drive.google.com/a/google.com/file/d/1n-5Nf5haoyT9V3hflwfrrSnyy5cVPwkT/view?usp=drivesdk)

##### Another example: audit logs

To see logs for  all audited actions that took place in the project during the specified time interval:

1. For the resource type, select **Audited Resources > All services**
1. For the log type, select** All logs**
1. For the time interval, you might have to experiment, depending on how long your project has been up.

The Logs Viewer now shows all audited actions that took place in the project during the specified time interval:

![image](https://drive.google.com/a/google.com/file/d/1Gh9szazWATftNkt40hqFrsS1sAqwDBsD/view?usp=drivesdk)

##### Exporting logs

Audit logs contain the records of who did what. For long-term retention of these records, the recommended practice is to create exports for audit logs. You can do that by clicking on **Create Export**:

![image](https://drive.google.com/a/google.com/file/d/1LuBLsnYp7SpPkOH9_XUDYAFCBBZapZPW/view?usp=drivesdk)

Give your sink a name, and select the service  and destination to which you will export your logs. We recommend using a less expensive class of storage for exported audit logs, since they are not likely to be accessed frequently. For this example, create an export for audit logs to Google Cloud Storage.

Click **Create Sink**. Then follow the prompts to create a new storage bucket and export logs there:

![image](https://drive.google.com/a/google.com/file/d/1eqHGC8xpJoUz5HXuHOXcOWp64jHzpnLa/view?usp=drivesdk)

### Stackdriver Error Reporting

#### Error Reporting Overview

Stackdriver Error Reporting (_[documentation_](https://cloud.google.com/error-reporting/docs/)) automatically groups errors depending on the stack trace message patterns and shows the frequency of each error groups. The error groups are generated automatically, based on stack traces.

On opening an error group report, operators can access to the exact line in the application code where the error occurred and reason about the cause by navigating to the line of the source code on Google Cloud Source Repository. 

#### Using Error Reporting

You can access Error Reporting by selecting **Error Reporting ** from the GCP navigation menu:

![image](https://drive.google.com/a/google.com/file/d/1mcd7pa-5nayU9VEX4L2BeNDTLagZ-xxc/view?usp=drivesdk)

> **Note:** Error Reporting can also let you know when new errors are received; see ["Notifications for Error Reporting"](https://cloud.google.com/error-reporting/docs/notifications) for details.

undefinedTo get started, select any open error by clicking on the error in the **Error** field:

![image](https://drive.google.com/a/google.com/file/d/1--c9HzOj0Llw5F1VelGYeub9ZYGxGXlp/view?usp=drivesdk)

The** Error Details** screen shows you when the error has been occurring in the timeline and provides the stack trace that was captured with the error.  **Scroll down** to see samples of the error:

![image](https://drive.google.com/a/google.com/file/d/12UeYNWAstMEvQzDv7hn90bbJcJEwtZ2p/view?usp=drivesdk)

undefinedClick **View Logs** for one of the samples to see the log messages that match this particular error:

![image](https://drive.google.com/a/google.com/file/d/1WMaiLkmcDpna-DdkRuOceTJr9WNrio7T/view?usp=drivesdk)

You can expand any of the messages that matches the filter to see the full stack trace:

![image](https://drive.google.com/a/google.com/file/d/1UyNGlV9kohaordGLDyTK2wyfZNvKET07/view?usp=drivesdk)

# OpenCensus to become OpenTelemetry

The Stackdriver Sandbox project uses the [OpenCensus libraries](https://opencensus.io/) for collection of traces and metrics. OpenCensus provides a set of open-source libraries for a variety of languages, and the trace/metric data collected with these libraries can be exported to a variety of backends, including Stackdriver.

For the next major release, OpenCensus is combining with the [OpenTracing project](https://opentracing.io/) to create a single solution, called [OpenTelemetry](https://opentelemetry.io/). OpenTelemetry will support basic context propagation, distributed traces, metrics, and other signals in the future, superseding both OpenCensus and OpenTracing.