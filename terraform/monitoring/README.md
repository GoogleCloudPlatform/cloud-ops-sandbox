Hipster Shop Monitoring Terraform
================================================================================

## What's included
Note: the contents of this directory are automatically installed when creating a Cloud Operations Sandbox

This directory contains documented [Terraform] for provisioning monitoring examples
for the microservices contained in the demo application provisioned by Cloud Operations Sandbox.

Please note that in order to provision these monitoring examples a [Monitoring Workspace] 
must be associated with your project.

Note: the monitoring examples created in this directory are an opinionated example. It demonstrates best-practice methods 

[Terraform]: https://www.terraform.io/
[Monitoring Workspace]: https://cloud.google.com/monitoring/workspaces/create

## File Content Breakdown
### 01_uptime_checks.tf
1. [Uptime check] on the external IP address of the cluster. This default HTTP uptime check verifies that the root path of the application returns a 200 OK response every minute from 4 different regions with a 10 second timeout period. 
2. [Alerting policy] on the status of the uptime check. The policy raises an alert and notifies the notification channel via email when the uptime check returns non-200 responses more than twice over a 5 minute window.
3. Notification channel which configures the account owner's email to be set to a notification channel for alerting policy violations.

[![Uptime check](./docs/images/monitoring/uptime-check.png)](./docs/img/monitoring/uptime-check.png)

[Uptime check]: https://cloud.google.com/monitoring/uptime-checks
[Alerting policy]: https://cloud.google.com/monitoring/alerts

### 02_dashboards.tf
This file contains custom dashboards for each service as well as a User Experience Dashboard which represents metrics surrounding a user's interactions with the application. The four [golden signals of monitoring] are represented within each dashboard for each service. The metrics chosen utilize a combination of native Kubernetes metrics available through Cloud Monitoring, [Istio] metrics exposed through installation of Istio, and OpenCensus custom metrics. 

[![Dashboards list](./docs/images/monitoring/dashboards-list.png)](./docs/img/monitoring/dashboards-list.png)
[![Sample dashboard](./docs/images/monitoring/sample-dashboard.png)](./docs/img/monitoring/sample-dashboard.png)

[golden signals of monitoring]: https://landing.google.com/sre/sre-book/chapters/monitoring-distributed-systems/#:~:text=The%20four%20golden%20signals%20of,system%2C%20focus%20on%20these%20four.&text=The%20time%20it%20takes%20to%20service%20a%20request
[Istio]: https://istio.io/

### 03_services.tf
This file contains the service specific details for the SLOs and Alerting Policies placed on each service. Each microservice in the demo application has monitoring created for it using either a Cloud Monitoring Custom Service or an Istio Service that is automatically created by Cloud Monitoring. Istio services are only available through the installation and usage of Istio service mesh. 

Each service has the following parameters that can be fine tuned:
1. availability_goal - the goal (as a decimal) for the availability SLO (defined as the percentage of successful requests). Ex. 0.9 = 90% of requests return as successful. 
2. availability_burn_rate - the [error budget burn rate] threshold for the availability SLO. If the error budget burn rate exceeds this value, then the associated alerting policy raises an alert. 
3. latency_goal - the goal (as a decimal) for the latency SLO (defined as the percentage of successful requests). Ex. 0.9 = 90% of requests return in under the latency threshold.
4. latency_threshold - the upper bound (in ms) for a request to return in to be considered successful. 
5. latency_burn_rate - the [error budget burn rate] threshold for the latency SLO. If the error budget burn rate exceeds this value, then the associated alerting policy raises an alert.

[![Services list](./docs/images/monitoring/services-list.png)](./docs/img/monitoring/services-list.png)

[error budget burn rate]: https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate
### 04_slos.tf
This file contains the definitions of [Service Level Objectives] (SLOs) for each service (for both custom services and Istio services). 
1. Availability SLO - this SLO is defined as the ratio of the number of successful requests (200 OK response code) to the number of total requests (non-4XX response code). The metric utilized is the Istio server request count metric which allows filtering by response code. The goal for the SLO is configured for each service in the 03_services.tf file.
2. Latency SLO - this SLO is defined as the ratio of the number of successful requests (200k OK response code) that return in under the latency threshold value to the number of total successful requests. The metric utilized is the Istio server response latencies. The goal and latency threshold for the SLO is configured for each service in the 03_services.tf file.

[![SLO details](./docs/images/monitoring/slo-details.png)](./docs/img/monitoring/slo-details.png)

[Service Level Objectives]: https://landing.google.com/sre/sre-book/chapters/service-level-objectives
### 05_alerting_policies.tf
This file contains the definitions of alerting policies for each SLO defined in 04_slos.tf. The alerting policies are fired when the error budget burn rate is exceeded. The burn rates are configured for each service in the file 03_services.tf. More on [alerting on service level objectives] can be found here.

[alerting on service level objectives]: https://landing.google.com/sre/workbook/chapters/alerting-on-slos/

### 06_log_based_metric.tf
This file contains the specification of a metric using Cloud Logging's [log-based metric feature]. The metric is defined on a custom log being written to Cloud Logging by the Checkout Service. This log-based metric can then be used for a multitude of monitoring resources, and a custom dashboard is created using this metric in its chart. 

[![Log based metric](./docs/images/monitoring/log-based-metric.png)](./docs/img/monitoring/log-based-metric.png)

[log-based metric feature]: https://cloud.google.com/logging/docs/logs-based-metrics