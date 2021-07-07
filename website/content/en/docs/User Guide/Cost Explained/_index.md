---
title: "Breaking Down Cloud Operations Sandbox Cost"
linkTitle: "Sandbox Cost Explained"
weight: 2
---
{{% pageinfo %}}
* [Cloud Operations Sandbox Cost Estimations](#Cloud-Operations-Sandbox-Cost-Estimations)
  * [GCP Calculator](#GCP-Calculator)
  * [Sandbox Compute Cost Estimations](#Sandbox-Compute-Cost-Estimations)
{{% /pageinfo %}}
 
## Cloud Operations Sandbox Cost Estimations
Cloud Operations Sandbox Cost is made up of compute cost, storage and usage of network traffic and additional services like Cloud Operations Suite. While some of the cost, like GKE infrastructure is constant, for some services cost is a factor of usage. Note, that some of Sandbox costs fall under the [free tier](https://cloud.google.com/free/docs/gcp-free-tier#free-tier), but not not all.
To learn more about billing and pricing please refer to: [Google Cloud Pricing Overview](https://cloud.google.com/pricing/), [Google’s Pricing philosophy](https://cloud.google.com/pricing/philosophy/), [GCP's Billing](https://cloud.google.com/billing/docs).

The GCP billing page will break down your expenses by resource usage. To view billing information for your project in the console go to the [Billing section](https://console.cloud.google.com/billing) in the left navigation menu.

![image](/docs/images/user-guide/57-billing-menu.png)

![image](/docs/images/user-guide/58-billing-console.png)
 
### GCP Calculator
GCP has transparent pricing which is applied per resource. You can plan and estimate pricing using the [pricing calculator](https://cloud.google.com/products/calculator). One great feature of Google Cloud Platform is [sustained use discounts](https://cloud.google.com/compute/docs/sustained-use-discounts), which can save up to 30% in costs as a credit applied to your account. This allows you later to see exact costs attributed to usage, so you can more accurately reduce usage going forward."

To break down the cost we will use a GCP calculator. As network, storage and [observability cost](https://cloud.google.com/stackdriver/pricing) are very minimal due to the low volume, in the next section we will focus on the cost of the infrastructure. 

### Sandbox Compute Cost Estimations
You can view the provisioned resources in [Terraform code](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/terraform) you can see the exact resources created or in GCP's console.

![image](/docs/images/user-guide/59-resources-console.png)

In order to use the calculator you should first select a product from the scrolling list and fill the needed variables. We should do the same for each one of the products.
 
**Resources Information**
Region: "us-east1" 
- Loadgen Cluster 1x "n1-standard-2" 
- GKE cluster (for the hipster shop microservices) 4x "n1-standard-2"
- App Engine (Standard, F1)
- SQL PostgresQL - "db-f1-micro" 


**GKE Clusters**
Choose GKE Standard -> fill the number of machines, machine type and region and at the end press 'add to the estimate'
![image](/docs/images/user-guide/60-gke-billing.png)

**App Engine**
For AppEngine -we should choose 'Standard' - F1, as AppEngine scale to 0 when not used in our learning environment with periodical test our cost fall under the free tier ([AppEngine pricing](https://cloud.google.com/appengine/pricing)) 
![image](/docs/images/user-guide/61-AppEngine-billing.png)

> You can see detailed usage and billing cost in the [AppEngine console](https://console.cloud.google.com/appengine)
![image](/docs/images/user-guide/66-AppEngine-billing-ui.png)

**Cloud SQL**
Similar to before, we should choose the product i.e. Cloud SQL.

![image](/docs/images/user-guide/67-cloudsql-calc-menu.png)
Then we should choose  PostgresQL -> and fill the instance type, region as before. In regards to storage we can fill 10GB which is the default.
![image](/docs/images/user-guide/62-cloudsql-billing.png)

Similarly we can also add to the estimation the cost of our storage(buckets),  in order to estimate that cost we will need to get how much data we are using.
You can view this information easily using Metrics Explorer, by choosing Resource Type: `GCS Bucket` and Metric `Total bytes`

![image](/docs/images/user-guide/63-storage-metrics.png)
As you can see it is well below 1GB which costs $0.02.
At the end you will have an estimation that includes all the components, and you also save it or email it to be referenced later. Which is ~$240 a month for Sandbox components.

> Please note that is only estimation for the compute components and additional charges like networking and metrics will be added based on usage. 

![image](/docs/images/user-guide/64-cost-est.png)
![image](/docs/images/user-guide/65-cost-est2.png)
