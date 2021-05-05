---
title: "Explore your project"
linkTitle: "Explore your project"
weight: 20
---

{{% pageinfo %}}
* [Explore your project in GCP](#explore-your-project-in-gcp)
* [Explore Cloud Monitoring](#explore-cloud-monitoring)
* [Shop like a hipster](#shop-like-a-hipster)
* [Run the load generator](#run-the-load-generator)
{{% /pageinfo %}}

## Explore your project in GCP

In another browser tab, navigate to the GCP GKE Dashboard URL, which takes you to the Kubernetes Engine ([documentation](https://cloud.google.com/kubernetes-engine/docs/)) **Workloads** page for the project created by the installer:

![image](/docs/images/user-guide/4-cloudconsole.png)

## Explore Cloud Monitoring

In a new browser tab, navigate to the GCP Monitoring Workspace URL, which takes you to the Cloud Monitoring ([documentation](https://cloud.google.com/monitoring)) **Workspace** page for your new project. The console may take some time to create a new workspace. Afterward, you'll be able to see a few dashboards generated through Cloud Operations tools.

![image](/docs/images/user-guide/19-gcp-monitoring-overview.png)

## Shop like a hipster!

In a new browser tab, navigate to the Hipster Shop URL, where you can "purchase" everything you need for your hipster lifestyle using a mock credit card number:

![image](/docs/images/user-guide/2-hipstershop.png)

## Run the load generator

In another browser tab, navigate to the load-generator URL, from which you can simulate users interacting with the application to generate traffic. For this application, values like 100 total users with a spawn rate of 2 users per second are reasonable. Fill in the **Host** field with the "Hipster shop web address" from the installation stage if it isn't prepopulated. Click the **Start swarming** button to begin generating traffic to the site.

![Locust example](/docs/images/user-guide/3-locust.png)

From here, you can explore how the application was deployed, and you can use the navigation menu to bring up other GCP tools.