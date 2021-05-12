---
title: "SLIs, SLOs and Burn rate Alerts"
linkTitle: "SLIs, SLOs and Burn rate Alerts"
weight: 40
---


{{% pageinfo %}}
* [Overview](#SLIs,-SLOs-and-Burn-rate-Alerts-Overview)
* [Services SLOs](#Services-SLOs)
* [Configure your own SLIs and SLOs](#Configure-your-own-SLIs-and-SLOs)
* [Configure Burn Rate Alerts](#Configure-Burn-Rate-Alerts)
{{% /pageinfo %}}


#### SLIs, SLOs and Burn rate Alerts Overview 
Cloud Operations Sandbox comes with several predefined SLOs (Service level objectives), that allow you to measure your users happiness. To learn more about SLIs and SLOs [SRE fundamentals.](https://cloud.google.com/blog/products/devops-sre/sre-fundamentals-slis-slas-and-slos)

Cloud operations suite provides **service oriented monitoring**, that means that you are configuring SLIs, SLOs and Burning Rates Alerts for a 'service'.  

The first step in order to create SLO is to **ingest the data**. For GKE services telemetry and dashboards comes out of the box, but you can also ingest additional data and [create custom metrics.](#Monitoring-and-logs-based-metrics)

Then you need to **define your service**, Cloud Operations Sandbox' services are already detected since Istio's services are automatically detected and created. But to demonstrate that you can create your own services, it also deploys custom services using [Terraform](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/terraform/monitoring).

You can find all the services under [monitoring → services → Services Overview](https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring/ui/svc-overview), and you can create your own [custom service.](https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring/ui/define-svc)

![image](/docs/images/user-guide/37-services-overview.png)
#### Services SLOs  

The *predefined SLOs* are also deployed as part of [Terraform code](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/terraform/monitoring/04_slos.tf) and currently are for the mentioned custom services, the Istio service and Rating service.  

**Custom services SLOs**
``` 
Custom service availability SLO: 90% of HTTP requests are successful within the past 30 day windowed period
```

``` 
Custom service Latency SLO: 90% of requests return in under 500 ms in the previous 30 days
```  
To view the exiting SLOs, in the Services Overview screen choose the desired service.

*For example for checkoutservice*:

![image](/docs/images/user-guide/47-choose-checkout-custom-service.png)

![image](/docs/images/user-guide/36-checkoutservice-overview.png)

**Additional predefined SLOs:**

```
Istio service availability SLO: 99% of HTTP requests are successful within the past 30 day windowed period
```
```
Istio service latency SLO: 99% of requests return in under 500 ms in the previous 30 days
```
```
Rating service availability SLO: 99% of HTTP requests are successful within the past 30 day windowed period
```
```
Rating service latency SLO: 99% of requests that return in under 175 ms in the previous 30 days
```
```
Rating service's data freshness SLO: during a day 99.9% of minutes have at least 1 successful recollect API call
```

#### Configure your own SLIs and SLOs

> **Remember** The purpose of defining SLIs and SLOs is to improve your user's experience, your SLOs scope is a [User journey](https://cloud.google.com/solutions/defining-SLOs#why_slos). Therefore your first step should be to *identify the most critical User Journey(CUJ)* to your business, then *identify the metrics* that measure your customer experience as closely as possible and *ingest* that data.  

You can [configure your own SLIs and SLOs](https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring/ui/create-slo) for an existing service or for your own custom service.  

#### Example: configuring the checkout service
1. In the service screen you will choose Create SLO:
![image](/docs/images/user-guide/39-checkout-service.png)
2.Then you will set your SLI, you need to choose SLI type and the method(request vs window based):
![image](/docs/images/user-guide/42-checkoutservice-sli.png)
3. Then you will define your metric and you can also preview its performance based on historical data:
![image](/docs/images/user-guide/41-checkoutservice-define-sli.png)
4. Then you will configure your SLO, your target in a specific time window. You can also choose between [rolling window or a calendar window](https://sre.google/workbook/implementing-slos/):
![image](/docs/images/user-guide/43-set-slo.png)

#### Configure Burn Rate Alerts

After you create the SLO, you can create [Burn Rate Alerts](https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate)for those.

Several *predefined policies* are deployed as part of [Terraform](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/blob/master/terraform/monitoring/05_alerting_policies.tf). You can view them in the service screen, edit them, or [create your own](https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate).

Let's continue with the Istio checkoutservice SLO you created [in the previous section:](#Let's-demonstrate-that-using-the-checkout-auto-defined-Istio-service:)

1. In the service screen you will be able to see your new SLO and you will choose 'Create Alerting Policy'

![image](/docs/images/user-guide/46-crete-slo-burn-alert.png)
2. Then you will want to set the alert's condition, who and how they will be notified and additional instructions:  
![image](/docs/images/user-guide/44-set-slo-burn-alert.png)
3. After it will be created you could see it and incidents that might be triggered due to it in the service screen and in the Alerting screen:
![image](/docs/images/user-guide/45-burn-rate-final.png)
