---
title: "Home"
linkTitle: "Home"
weight: 1
menu:
  main:
    weight: 1
---


# Cloud Operations Sandbox (Alpha)


Cloud Operations Sandbox is an open-source tool that helps practitioners to learn Service Reliability Engineering practices from Google and apply them on their cloud services using [Cloud Operations](https://cloud.google.com/products/operations) (formerly Stackdriver).
It is based on [Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo), a cloud-native microservices application.

Sandbox offers:

* **Demo Service** - an application built using microservices architecture on modern, cloud-native stack.
* **One-click deployment**  - a script handles the work of deploying the service to Google Cloud Platform.
* **Load Generator** - a component that produces synthetic traffic on a demo service.
* (Soon) **SRE Runbook** - pre-built routine procedures for operating the deployed sample service that follow best SRE practices using Cloud Operations.

## Why Sandbox

Google Cloud Cloud Operations is a suite of tools that helps you gain full observability of your code and applications.
You might want to take Cloud Operations to a "test drive" in order to answer the question, "will it work for my application needs"?
The most effective way to learn is by testing the tool in "real-life" conditions, but without risking a production system.
With Sandbox, we provide a tool that automatically provisions a new demo cluster, which receives traffic, simulating real users. Practitioners can experiment with various Cloud Operations tools to solve problems and accomplish standard SRE tasks in a sandboxed environment.

