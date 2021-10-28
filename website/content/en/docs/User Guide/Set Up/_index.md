---
title: "Set Up"
linkTitle: "Set Up"
weight: 10
---
{{% pageinfo %}}
* [Deploy the Sandbox](#deploy-the-sandbox)
* [Recovering from session timeout](#recovering-from-session-timeout)
{{% /pageinfo %}}

## Deploy the Sandbox

In a new browser tab, navigate to the Cloud Operations Sandbox [website](/) and follow the instructions there:

Click the **Open in Google Cloud Shell** button. You might have to click Proceed on a second dialog if you haven't run Cloud Shell before.

Additionally, there will be a window that opens asking whether you trust the custom container. Check the "Trust" box in order to authenticate.

![image](/docs/images/user-guide/TrustImage.png)

After the shell starts, the Cloud Operations Sandbox repository is cloned to your shell container, and you are placed in the `cloud-ops-sandbox/terraform` directory. The installer script should start running automatically.

The installer script performs the following tasks:

-  Enables the necessary GCP features
-  Creates a GCP project named "Cloud Operations Sandbox Demo"
-  Creates and configures a GKE cluster and deploys the microservices that make up the Hipster Shop application
-  Starts a Compute Engine instance and runs [Locust](https://locust.io/), a load-generator application

The installation process takes a few minutes. When it completes, you see a message like the following:

```bash
********************************************************************************
Cloud Operations Sandbox deployed successfully!

     Google Cloud Console GKE Dashboard: https://console.cloud.google.com/kubernetes/workload?project=<project ID>
     Google Cloud Console Monitoring Workspace: https://console.cloud.google.com/monitoring?project=<project ID>
     Hipstershop web app address: http://XX.XX.XX.XX
     Load generator web interface: http://XX.XX.XX.XX
```

The URLs in this message tell you where to find the results of the installation:

> A Workspace will be created automatically for your project if you don't have one already, so you don't have to do anything explicitly with this URL.

-  The **Google Cloud Console GKE Dashboard** URL takes you to the Kubernetes Engine console for your deployment.

- The **Google Cloud Console Monitoring Workspace** URL takes you to the Cloud Monitoring console for your deployment.

-  The **Hipster Shop** URL takes you to the storefront.

-  The **load generator** URL takes you to an interface for generating synthetic traffic to Hipster Shop.

### Recovering from session timeout
Should your Cloud Shell session timeout due to user inactivity, you will need to launch the custom Cloud Shell image to access the `sandboxctl` command.
Click the [![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.png)](/) button on the [Cloud Operations Sandbox homepage](/) to restart the custom Cloud Shell
