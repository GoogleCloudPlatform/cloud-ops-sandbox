---
title: "Service Overview"
linkTitle: "Service Overview"
weight: 3
---

{{% pageinfo %}}
* [Screenshots](#screenshots)
* [Architecture](#service-architecture)
* [Technologies](#technologies)
{{% /pageinfo %}}

This project contains a multi-tier microservices application.
It is a web-based e-commerce app called **“Hipster Shop”**, where users can browse items, add them to the cart, and purchase them.

### Screenshots

| Home Page | Checkout Screen |
|-----------|-----------------|
| [![Screenshot of store homepage](/docs/img/hipster-shop-frontend-1.png)](/docs/img/hipster-shop-frontend-1.png) | [![Screenshot of checkout screen](/docs/img/hipster-shop-frontend-2.png)](/docs/img/hipster-shop-frontend-2.png) |

### Service Architecture

**Hipster Shop** is composed of many microservices, written in different languages, that talk to each other over gRPC and REST API.
>**We are not endorsing the architecture of Hipster Shop as the best way to build such a shop!**
> The architecture is optimized for learning purposes and includes modern stack: Kubernetes, GKE, Istio,
> Cloud Operations, App Engine, gRPC, OpenTelemetry, and similar cloud-native technologies.

[![Architecture of
microservices](/docs/img/architecture-diagram.png)](/docs/img/architecture-diagram.png)

Find the **gRPC protocol buffer descriptions** in the [`./pb` directory](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/pb).

| Service | Language | Description |
|---------|----------|-------------|
| [frontend](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/src/frontend) | Go | Exposes an HTTP server to serve the website. Does not require signup/login, and generates session IDs for all users automatically. |
| [cartservice](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/src/cartservice) |  C# | Manages the items in the user's shipping cart by using Redis. |
| [productcatalogservice](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/src/productcatalogservice) | Go | Provides the list of products from a JSON file and the ability to search and retrieve products. |
| [currencyservice](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/src/currencyservice) | Node.js | Converts one currency to another, using real values fetched from  the European Central Bank. It's the highest QPS service. |
| [paymentservice](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/src/paymentservice) | Node.js | Charges the given credit card info (hypothetically😇) with the given amount and returns a transaction ID. |
| [shippingservice](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/src/shippingservice) | Go | Gives shipping-cost estimates based on the shopping cart. Ships items to the given address (hypothetically😇). |
| [emailservice](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/src/emailservice) | Python | Sends users an order-confirmation email (hypothetically😇). |
| [checkoutservice](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/src/checkoutservice) | Go | Retrieves a user's cart, prepares the order, and orchestrates payment, shipping, and email notification. |
| [recommendationservice](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/src/recommendationservice) | Python | Recommends other products based on what's in the user's cart. |
| [adservice](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/src/adservice) | Java | Provides text ads based on given context words. |
| [loadgenerator](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/src/loadgenerator) | Python/Locust | Continuously sends requests that imitate realistic shopping flows to the frontend. |
| [ratingservice](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/src/ratingservice) | Python3 | Manages ratings of the shop's products. Runs on App Engine. |

### Technologies

* **[Kubernetes](https://kubernetes.io)/[GKE](https://cloud.google.com/kubernetes-engine/):**
  The app is designed to run on Google Kubernetes Engine.
* **[gRPC](https://grpc.io):** Microservices use a high volume of gRPC calls to
  communicate to each other.
* **[OpenTelemetry](https://opentelemetry.io/) Tracing:** Most services are
  instrumented using OpenTelemetry tracers and interceptors which handle trace context propagation through gRPC and HTTP.
* **[Cloud Operations APM and SRE](https://cloud.google.com/products/operations):** Many services
  are instrumented with **Profiling**, **Tracing**, **Debugging**, **Monitoring**, **Logging** and **Error Reporting**.
* **[Skaffold](https://github.com/GoogleContainerTools/skaffold):** A tool used for doing repeatable deployments. You can deploy to Kubernetes with a single command using Skaffold.
* **Synthetic Load Generation:** The application demo comes with dedicated load generation service that creates realistic usage patterns on Hipster Shop website using
  [Locust](https://locust.io/) load generator.
* **[Google App Engine](https://cloud.google.com/appengine):** PaaS for running Web applications and services.
* **[Google Cloud SQL](https://cloud.google.com/sql):** Fully managed relational database service for MySQL, PostgreSQL and SQL Server.

