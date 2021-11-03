---
title: "Cloud Debugger"
linkTitle: "Cloud Debugger"
weight: 60
---

{{% pageinfo %}}
* [Overview](#debugger-overview)
* [Using Debugger](#using-debugger)
* [Download Source Code](#download-source-code)
* [Create and configure source repository](#create-and-configure-source-repository)
* [Upload source code to Debugger](#upload-source-code-to-debugger)
* [Create a Snapshot](#create-a-snapshot)
* [Create a logpoint](#create-a-logpoint)
{{% /pageinfo %}}

#### Debugger Overview

You might have experienced situations where you see problems in production environments but they can't be reproduced in test environments. To find a root cause, then, you need to step into the source code or add more logs of the application as it runs in the production environment. Typically, this would require re-deploying the app, with all associated risks for production deployment.

Cloud Debugger ([documentation](https://cloud.google.com/debugger/docs/)) lets developers debug running code with live request data. You can set breakpoints and log points on the fly. When a breakpoint is hit, a snapshot of the process state is taken, so you can examine what caused the problem. With log points, you can add a log statement to a running app without re-deploying, and without incurring meaningful performance costs.

You do not have to  add any instrumentation code to your application to use Cloud Debugger. You start the debugger agent in the container running the application, and  you can then use the Debugger UI to step through snapshots of the running code.

The following Online Boutique microservices are configured to capture debugger data:

-  Currency service
-  Email service
-  Payment service
-  Recommendation service

#### Using Debugger

To bring up the Debugger, select **Debugger** from the navigation panel on the GPC console:

![image](/docs/images/user-guide/14-debugger.png)

As you can see, Debugger requires access to source code to function.  For this exercise, you'll download the code locally and link it to Debugger.

##### Download source code

In **Cloud Shell**, issue these **commands** to download a release of the Sandbox source code and extract the archive:

```bash
cd ~
wget https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/archive/next19.tar.gz
tar -xvf next19.tar.gz
cd cloud-ops-sandbox-next19
```

##### Create and configure source repository

To create a Cloud Source Repository for the source code and to configure Git access, issue these commands in Cloud Shell:

```bash
gcloud source repos create google-source-captures
git config --global user.email "user@domain.tld" # substitute with your email
git config --global user.name "first last"       # substitute with your name
```

##### Upload source code to Debugger

In the Debugger home page, **copy** the command (_don't click the button!_) in the "Upload a source code capture to Google servers" box, but **don't include the `LOCAL_PATH` variable**. (You will replace this with another value before executing the command.)

![image](/docs/images/user-guide/15-codeupload.png)

Paste the command into your Cloud Shell prompt and add a space and a period:

```bash
gcloud beta debug source upload --project=cloud-ops-sandbox-68291054 --branch=6412930C2492B84D99F3 .
```

Enter _RETURN_ to execute the command.

In the Debugger home page, click the **Select Source** button under "Upload a source code capture" option, which will then open the source code:

![image](/docs/images/user-guide/16-selectsource.png)

You are now ready to debug your code!

##### Create a snapshot

Start by using the Snapshot functionality to understand the state of your variables.  In the Source capture tree, open the **`server.js`** file under **src** > **currencyservice.** 

Next, click on **line 121** to create a snapshot. in a few moments, you should see a snapshot be created, and you can view the values of all variables at that point on the right side of the screen:

![image](/docs/images/user-guide/17-snapshot.png)


##### Create a logpoint

Switch to the **Logpoint** tab on the right side. To create the logpoint:

1. Again, click on **line 121** of **`server.js`** to position the logpoint.
1. In the **Message** field, type "testing logpoint" to set the message that will be logged.
1. Click the **Add** button. 

To see all messages that are being generated in Cloud Logging from your logpoint, click the **Logs** tab in the middle of the UI. This brings up an embedded viewer for the logs:

![image](/docs/images/user-guide/18-logpoint.png)