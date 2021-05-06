---
title: "Learn Ops Management"
linkTitle: "Learn Ops Management"
weight: 30
---

## Ops Management Overview

As the cloud-native microservice architecture, which promises scalability and flexibility benefits, gets more popular, developers and administrators need tools that can work across cloud-based distributed systems.

Cloud Operations provides products for both developers and administrators, this section introduces the products and their general audiences.  The tools are covered in more detail later.
Application developers need to be able to investigate the cause of problems in applications running in distributed environments, and in this context, the importance of **Application Performance Management (APM)** has increased. Cloud Operations provides 3 products for APM:

-  [Cloud Trace](./cloud_trace.md)
-  [Cloud Profiler](./cloud_profiler.md)
-  [Cloud Debugger](./cloud_debugger.md)

Similarly, cloud-native, microservice-based applications complicate traditional approaches used by administrators for monitoring system health: it's harder to observe your system health when the number of instances is flexible and the inter-dependencies among the many components are complicated. In the last few years, **Site Reliability Engineering (SRE)** has become recognized as a practical approach to managing large-scale, highly complex, distributed systems. Ops Management provides the following tools that are useful for SRE:

-  [Cloud Monitoring](./cloud_monitoring.md)
-  [Cloud Logging](./cloud_logging.md)
-  [Cloud Error Reporting](./cloud_error_reporting.md)
-  [SLIs, SLOs and Burn rate Alerts Overview](./cloud_slo_monitoring.md)

You can find the Ops Management products in the navigation panel on the GCP Console:

![image](/docs/images/user-guide/5-operations-products.png)