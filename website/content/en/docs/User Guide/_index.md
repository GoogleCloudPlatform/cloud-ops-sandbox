---
title: "User Guide"
linkTitle: "User Guide"
weight: 4
menu:
  main:
    weight: 2
---

{{% pageinfo %}}
* [Overview](#overview)
* [Architecture](#architecture-of-the-hipster-shop-application)
* [Prerequisites](#prerequisites)
* [OpenCensus to become OpenTelemetry](#opencensus-to-become-opentelemetry)
{{% /pageinfo %}}

## Overview

The Cloud Operations Sandbox is intended to make it easy for you to deploy and run a non-trivial application that lets you explore the Google Cloud Platform services, particularly the [Cloud Operations](http://cloud.google.com/products/operations) (formerly Stackdriver) product suite. Cloud Operations is a suite of tools that helps you gain full observability into your code and applications.

The Online Boutique application used in the sandbox is intended to be sufficiently complex such that you can meaningfully experiment with it, and the Sandbox automatically provisions a new demo cluster, configures and deploys Online Boutique, and simulates real users.

With the Sandbox running, you can experiment with various Cloud Operations tools to solve problems and accomplish standard SRE tasks in a sandboxed environment without impacting your production monitoring setup.

## Architecture of the Online Boutique application

The Online Boutique application consists of a number of microservices, written in a variety of languages, that talk to each other over gRPC.

![image](/docs/images/user-guide/1-architecture.png)

**Note:** We are not endorsing this architecture as the best way to build a real online store. This application is optimized for demonstration and learning purposes.  It illustrates a large number of cloud-native technologies, uses a variety of programming languages, and provides an environment that can be explored productively with Cloud Operations tools.

The Git repository you cloned has all the source code, so you can explore the implementation details of the application. See the repository [README](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/blob/main/README.md) for a guided tour.

# Prerequisites

You must have an active Google Cloud Platform Billing Account. If you already have one, you can skip this section.

Otherwise, to create a GCP Billing Account, do the following:

1. Go to the Google Cloud Platform [Console](https://console.cloud.google.com/) and sign in (if you have an account), or sign up (if you don't have an account).
1. Select **Billing** from the navigation panel and follow the instructions.

For more information, see ["Create a new billing account"](https://cloud.google.com/billing/docs/how-to/manage-billing-account).

# OpenCensus to become OpenTelemetry

The Cloud Operations Sandbox project uses the [OpenCensus libraries](https://opencensus.io/) for collection of traces and metrics. OpenCensus provides a set of open-source libraries for a variety of languages, and the trace/metric data collected with these libraries can be exported to a variety of backends, including Cloud Monitoring.

For the next major release, OpenCensus is combining with the [OpenTracing project](https://opentracing.io/) to create a single solution, called [OpenTelemetry](https://opentelemetry.io/). OpenTelemetry will support basic context propagation, distributed traces, metrics, and other signals in the future, superseding both OpenCensus and OpenTracing.