Hipster Shop Monitoring Terraform
================================================================================

## What's included
This directory contains documented [Terraform] for provisioning monitoring examples
for the microservices contained in the demo application provisioned by Cloud Operations Sandbox.

Please note that in order to provision these monitoring examples a [Monitoring Workspace] 
must be associated with your project.

Note: the monitoring examples created in this directory are an opinionated example. It demonstrates best-practice methods 

[Terraform]: https://www.terraform.io/
[Monitoring Workspace]: https://cloud.google.com/monitoring/workspaces/create

## File Content Breakdown
### 01_uptime_checks.tf
1. [Uptime check] on the external IP address of the cluster. This default HTTP uptime check verifies that the root path of the application returns a 200 OK response every minute from 6 different regions with a 10 second timeout period. 
2. [Alerting policy] on the status of the uptime check. The policy raises an alert and notifies the notification channel via email when the uptime check returns non-200 responses more than twice over a 5 minute window.
3. Notification channel which configures the account owner's email to be set to a notification channel for alerting policy violations.

[Uptime check]: https://cloud.google.com/monitoring/uptime-checks
[Alerting policy]: https://cloud.google.com/monitoring/alerts

### 02_dashboards.tf
This file contains custom dashboards for each service as well as a User Experience Dashboard which represents metrics surrounding a user's interactions with the application. The four [golden signals of monitoring] are represented within each dashboard for each service. The metrics chosen utilize a combination of native Kubernetes metrics available through Cloud Monitoring, [Istio] metrics exposed through installation of Istio, and OpenCensus custom metrics. 

[golden signals of monitoring]: https://landing.google.com/sre/sre-book/chapters/monitoring-distributed-systems/#:~:text=The%20four%20golden%20signals%20of,system%2C%20focus%20on%20these%20four.&text=The%20time%20it%20takes%20to%20service%20a%20request
[Istio]: https://istio.io/

### 03_services.tf
### 04_slos.tf
### 05_alerting_policies.tf
### 06_log_based_metric.tf