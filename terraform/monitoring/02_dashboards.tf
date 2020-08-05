# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Creates a dashboard for the general user experience - it contains metrics
# that reflect how users are interacting with the demo application such as latency
# of requests, distribution of types of requests, and response types. The JSON object
# containing the exact details of the dashboard can be found in the 'dashboards' folder.
resource "google_monitoring_dashboard" "userexp_dashboard" {
	dashboard_json = file("./dashboards/userexp_dashboard.json")
}

# Creates a dashboard for the frontend service. The details of the charts
# in the dashboard can be found in the JSON specification file.
resource "google_monitoring_dashboard" "frontend_dashboard" {
  dashboard_json = file("./dashboards/frontend_dashboard.json")
} 

# Creates a dashboard for the adservice. The details of the charts
# in the dashboard can be found in the JSON specification file.
resource "google_monitoring_dashboard" "adservice_dashboard" {
  dashboard_json = file("./dashboards/adservice_dashboard.json")
}

# Ceates a dashboard for the recommendationservice. The details of the charts
# in the dashboard can be found in the JSON specification file.
resource "google_monitoring_dashboard" "recommendationservice_dashboard" {
  dashboard_json = file("./dashboards/recommendationservice_dashboard.json")
}

# Create generic dashboards for three of the microservices. Since all three microservices
# will share the same charts across their dashboards, we can leverage Terraform template files
# in order to reproduce identical dashboards for each microservice.

# Define specifics for each of the services that will receive a generic dashboard.
# We need the service name for dashboard and chart titles, and we need the service ID to use as a metadata filter.
variable "services" {
  type = list(object({
    service_name = string,
    service_id = string
  }))
  default = [
    {
      service_name = "Payment Service"
      service_id = "paymentservice"
    },
    {
      service_name = "Email Service"
      service_id = "emailservice"
    },
    {
      service_name = "Shipping Service"
      service_id = "shippingservice"
    }
  ]
}

# Iterate over the services that we defined and create a dashboard template file for each one using
# the template file defined in the 'dashboards' folder.
data "template_file" "dash_json" {
  template = "${file("./dashboards/generic_dashboard.tmpl")}"
  count    = "length(var.services)"
  vars     = {
    service_name = "${var.services[count.index].service_name}"
    service_id   = "${var.services[count.index].service_id}"
  }
}

# Create GCP Monitoring Dashboards using the rendered template files that were created in the data
# resource above. This produces one dashboard for each microservice that we defined above.
resource "google_monitoring_dashboard" "service_dashboards" {
  count = "length(var.services)"
  dashboard_json = <<EOF
${data.template_file.dash_json[count.index].rendered}
EOF
}
