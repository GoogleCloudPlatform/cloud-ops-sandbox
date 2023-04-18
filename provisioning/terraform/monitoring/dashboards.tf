# Copyright 2023 Google LLC
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


locals {
  # List of services to use for provisioning generic dashboards
  generic_services = [
    {
      name = "Payment Service"
      id   = "paymentservice"
    },
    {
      name = "Email Service"
      id   = "emailservice"
    },
    {
      name = "Shipping Service"
      id   = "shippingservice"
    }
  ]
  cluster_vars = {
    cluster_name = var.gke_cluster_name
  }
}

resource "google_monitoring_dashboard" "userexp_dashboard" {
  dashboard_json = templatefile("${var.filepath_configuration}/dashboards/userexp_dashboard.json", local.cluster_vars)
}

# Creates a dashboard for the frontend service. The details of the charts
# in the dashboard can be found in the JSON specification file.
resource "google_monitoring_dashboard" "frontend_dashboard" {
  dashboard_json = templatefile("${var.filepath_configuration}/dashboards/frontend_dashboard.json", local.cluster_vars)
}

# Creates a dashboard for the adservice. The details of the charts
# in the dashboard can be found in the JSON specification file.
resource "google_monitoring_dashboard" "adservice_dashboard" {
  dashboard_json = templatefile("${var.filepath_configuration}/dashboards/adservice_dashboard.json", local.cluster_vars)
}

# Creates a dashboard for the recommendationservice. The details of the charts
# in the dashboard can be found in the JSON specification file.
resource "google_monitoring_dashboard" "recommendationservice_dashboard" {
  dashboard_json = templatefile("${var.filepath_configuration}/dashboards/recommendationservice_dashboard.json", local.cluster_vars)
}

# Creates a dashboard for the cartservice.
resource "google_monitoring_dashboard" "cartservice_dashboard" {
  dashboard_json = templatefile("${var.filepath_configuration}/dashboards/cartservice_dashboard.json", local.cluster_vars)
}

# Creates a dashboard for the checkoutservice.
resource "google_monitoring_dashboard" "checkoutservice_dashboard" {
  dashboard_json = templatefile("${var.filepath_configuration}/dashboards/checkoutservice_dashboard.json", local.cluster_vars)
}

# Creates a dashboard for the currencyservice.
resource "google_monitoring_dashboard" "currencyservice_dashboard" {
  dashboard_json = templatefile("${var.filepath_configuration}/dashboards/currencyservice_dashboard.json", local.cluster_vars)
}

# Creates a dashboard for the productcatalogservice.
resource "google_monitoring_dashboard" "productcatalogservice_dashboard" {
  dashboard_json = templatefile("${var.filepath_configuration}/dashboards/productcatalogservice_dashboard.json", local.cluster_vars)
}

# Creates a dashboard for custom log-based metric.
resource "google_monitoring_dashboard" "log_based_metric_dashboard" {
  dashboard_json = templatefile(
    "${var.filepath_configuration}/dashboards/log_based_metric_dashboard.json",
    {
      metric_name = google_logging_metric.checkoutservice_logging_metric.name,
    }
  )
}

# Generated dashboard configurations from a template.data "" "name" {
# Dashboards will show the same charts for different services.
data "template_file" "generated_configurations" {
  template = file("${var.filepath_configuration}/dashboards/generic_dashboard.tmpl")
  count    = length(local.generic_services)
  vars = merge(local.cluster_vars, {
    service_name = local.generic_services[count.index].name
    service_id   = local.generic_services[count.index].id
  })
}

resource "google_monitoring_dashboard" "generated_service_dashboards" {
  count          = length(local.generic_services)
  dashboard_json = <<EOF
${data.template_file.generated_configurations[count.index].rendered}
EOF
}
