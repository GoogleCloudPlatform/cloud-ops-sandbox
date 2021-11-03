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
* [SRE Recipes](#sre-recipes)
{{% /pageinfo %}}

## Explore your project in GCP

In another browser tab, navigate to the GCP GKE Dashboard URL, which takes you to the Kubernetes Engine ([documentation](https://cloud.google.com/kubernetes-engine/docs/)) **Workloads** page for the project created by the installer:

![image](/docs/images/user-guide/4-cloudconsole.png)

## Explore Cloud Monitoring

In a new browser tab, navigate to the GCP Monitoring Workspace URL, which takes you to the Cloud Monitoring ([documentation](https://cloud.google.com/monitoring)) **Workspace** page for your new project. The console may take some time to create a new workspace. Afterward, you'll be able to see a few dashboards generated through Cloud Operations tools.

![image](/docs/images/user-guide/19-gcp-monitoring-overview.png)

## Shop like a hipster!

In a new browser tab, navigate to the Online Boutique URL, where you can "purchase" everything you need for your hipster lifestyle using a mock credit card number:

![image](/docs/images/user-guide/2-online-boutique-frontend.png)

## Run the load generator
Cloud Ops Sandbox comes with [Locust load generator](https://locust.io/), to simulate users traffic.  

- In another browser tab, navigate to the load-generator URL (from the installation stage if it isn't populated).  
- Enter the number of **users** and **spawn rate**. For this application, we recommend to test 100 total users with a spawn rate of 2 users per second.  
- Fill in the **Host** field with the "Online Boutique web address" from the installation stage if it isn't populated.  
- Click the **Start swarming** button to begin generating traffic to the site.

This will produce traffic on the store from a loadgenerator pod:

![Locust example](/docs/images/user-guide/3-locust.png)


You can also run load testing from Cloud Shell using `sandboxctl` command, there are 2 available traffic patterns : 'basic' or 'step'.

```bash
sandboxctl loadgen <traffic_pattern>
```

For the entire `step test` duration ([current settings](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/src/loadgenerator/locust-tasks)), a load generator will generate step-shaped load profiles in the user traffic.

```bash
sandboxctl loadgen step
```

> Note: It is **not recommended** to spawn more than 150 users, as the Error rate will be high (>80%)


From here, you can explore how the application was deployed, and you can use the navigation menu to bring up other GCP tools.

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
