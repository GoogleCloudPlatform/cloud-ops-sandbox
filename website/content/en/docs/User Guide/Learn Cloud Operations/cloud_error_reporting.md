---
title: "Cloud Error Reporting"
linkTitle: "Cloud Error Reporting"
weight: 90
---

{{% pageinfo %}}
* [Overview](#error-reporting-overview)
* [Using Error Reporting](#using-error-reporting)
* [Errors Manufacturing ](#errors-manufacturing )
{{% /pageinfo %}}

#### Error Reporting Overview

Cloud Error Reporting ([documentation](https://cloud.google.com/error-reporting/docs/)) automatically groups errors depending on stack trace message patterns and shows the frequency of each error group. The error groups are generated automatically, based on stack traces.

On opening an error group report, operators can access to the exact line in the application code where the error occurred and reason about the cause by navigating to the line of the source code on Google Cloud Source Repository. 

#### Using Error Reporting

You can access Error Reporting by selecting **Error Reporting** from the GCP navigation menu:

![image](/docs/images/user-guide/31-errorrep.png)

> **Note:** Error Reporting can also let you know when new errors are received; see ["Notifications for Error Reporting"](https://cloud.google.com/error-reporting/docs/notifications) for details.

To get started, select any open error by clicking on the error in the **Error** field:

![image](/docs/images/user-guide/32-errordet.png)

The **Error Details** screen shows you when the error has been occurring in the timeline and provides the stack trace that was captured with the error.  **Scroll down** to see samples of the error:

![image](/docs/images/user-guide/33-samples.png)

Click **View Logs** for one of the samples to see the log messages that match this particular error:

![image](/docs/images/user-guide/34-logs.png)

You can expand any of the messages that matches the filter to see the full stack trace:

![image](/docs/images/user-guide/35-logdet.png)

#### Errors Manufacturing 

There are several ways in which you can experiment with Error Reporting tool and manufacture errors that will be reported and displayed in the UI. For the purpose of this demonstration we will use 2 tools that are coming with Cloud Operations Sandbox: Load Generator and SRE Recipes to simulate a situation that `Sandbox break`.

To simulate requests using the load generator we can use the UI or `sandboxctl`

```
$sandboxctl loadgen step
Redeploying Loadgenerator...
Loadgenerator deployed using step pattern
Loadgenerator web UI: http://<ExampleIP>
```

Then to `break` the service we will use sre-recipes (recipe2)

```
$sandboxctl sre-recipes break recipe2
Breaking service operations...
...done
```

In this case you will see in Error Reporting UI you will see a new reported error `Unhealthy pod, failed probe`

![image](/docs/images/user-guide/51-Error-Reporting-podfailed.png)

You can open it to see additional information, in the below example you can see that this error repeat itself several times in the last hour.

![image](/docs/images/user-guide/52-Error-Reporting-pod.png)

You can also press `View logs` to view detailed log information in Cloud Operations Logging.
  
![image](/docs/images/user-guide/53-Error-Reporting-logs.png)

> Note: at the end, don't forget to recover the service using `sandboxctl sre-recipes restore`. 
Another way to `break the service` is to use the load generator to overload the service with too many requests.
In the Load Generator UI( addressed provided about or using `sandboxctl describe`), we will start run a test with `500` users. 
> Note: Currently only load test <100 users would be successful.

![image](/docs/images/user-guide/56-Error-Reporting-loadgen.png)

In the UI you will see that the previous error `Unhealthy pod, failed probe`, in addition you can see an additional error `Container Downtime`:

![image](/docs/images/user-guide/54-Error-Reporting2.png)

![image](/docs/images/user-guide/55-Error-Reporting-failed-con-logs.png)