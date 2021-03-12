---
title: "Cloud Error Reporting"
linkTitle: "Cloud Error Reporting"
weight: 90
---

{{% pageinfo %}}
* [Overview](#error-reporting-overview)
* [Using Error Reporting](#using-error-reporting)
{{% /pageinfo %}}

#### Error Reporting Overview

Cloud Error Reporting ([documentation](https://cloud.google.com/error-reporting/docs/)) automatically groups errors depending on the stack trace message patterns and shows the frequency of each error groups. The error groups are generated automatically, based on stack traces.

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