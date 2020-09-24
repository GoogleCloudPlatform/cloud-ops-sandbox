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

# Create an alerting policy on the Availability SLO for the custom service.
# The definition of the SLO can be found in the file '03_service_slo.tf'.
# We alert on budget burn rate, alerting if burn rate exceeds the threshold defined for the service
resource "google_monitoring_alert_policy" "custom_service_availability_slo_alert" {
  count = length(var.custom_services)
  display_name = "${var.custom_services[count.index].service_name} Availability Alert Policy"
  combiner     = "AND"
  conditions {
    display_name = "SLO burn rate alert for availability SLO with a threshold of ${var.custom_services[count.index].availability_burn_rate}"
    condition_threshold {

      # This filter alerts on burn rate over the past 60 minutes
      filter     = "select_slo_burn_rate(\"projects/${var.project_id}/services/${google_monitoring_custom_service.custom_service[count.index].service_id}/serviceLevelObjectives/${google_monitoring_slo.custom_service_availability_slo[count.index].slo_id}\", 60m)"
      
      # The threshhold is determined by how quickly we burn through our error budget.
      # Example: if threshold_value = 2 then error budget is consumed in 15 days.
      # Details: https://landing.google.com/sre/workbook/chapters/alerting-on-slos/#4-alert-on-burn-rate 
      threshold_value = var.custom_services[count.index].availability_burn_rate
      comparison = "COMPARISON_GT"
      duration   = "60s"
    }
  }
  documentation {
    content = "Availability SLO burn for the ${var.custom_services[count.index].service_name} for the past 60m exceeded ${var.custom_services[count.index].availability_burn_rate}x the acceptable budget burn rate. The service is returning less OK responses than desired. Consider viewing the service logs or custom dashboard to retrieve more information or adjust the values for the SLO and error budget."
    mime_type = "text/markdown"
  }
}

# Create another alerting policy, this time on the SLO for latency for the custom service.
# Alert on budget burn rate as well.
resource "google_monitoring_alert_policy" "custom_service_latency_slo_alert" {
  count = length(var.custom_services)
  display_name = "${var.custom_services[count.index].service_name} Latency Alert Policy"
  combiner     = "AND"
  conditions {
    display_name = "SLO burn rate alert for latency SLO with a threshold of ${var.custom_services[count.index].latency_burn_rate}"
    condition_threshold {
      filter     = "select_slo_burn_rate(\"projects/${var.project_id}/services/${google_monitoring_custom_service.custom_service[count.index].service_id}/serviceLevelObjectives/${google_monitoring_slo.custom_service_latency_slo[count.index].slo_id}\", 60m)"
      threshold_value = var.custom_services[count.index].availability_burn_rate
      comparison = "COMPARISON_GT"
      duration   = "60s"
    }
  }
  documentation {
    content = "Latency SLO burn for the ${var.custom_services[count.index].service_name} for the past 60m exceeded ${var.custom_services[count.index].latency_burn_rate}x the acceptable budget burn rate. The service is responding slower than desired. Consider viewing the service logs or custom dashboard to retrieve more information or adjust the values for the SLO and error budget."
    mime_type = "text/markdown"
  }
}

# Create an alerting policy on the Availability SLO for the Istio service.
# The definition of the SLO can be found in the file '04_slos.tf'.
# Alerts on error budget burn rate.
resource "google_monitoring_alert_policy" "istio_service_availability_slo_alert" {
  count = length(var.istio_services)
  display_name = "${var.istio_services[count.index].service_name} Availability Alert Policy"
  combiner     = "AND"
  conditions {
    display_name = "SLO burn rate alert for availability SLO with a threshold of ${var.istio_services[count.index].availability_burn_rate}"
    condition_threshold {

      # This filter alerts on burn rate over the past 60 minutes
      # The service is defined by the unique Istio string that is automatically created
      filter     = "select_slo_burn_rate(\"projects/${var.project_id}/services/ist:${var.project_id}-zone-${var.zone}-cloud-ops-sandbox-default-${var.istio_services[count.index].service_id}/serviceLevelObjectives/${google_monitoring_slo.istio_service_availability_slo[count.index].slo_id}\", 60m)"
      threshold_value = var.istio_services[count.index].availability_burn_rate
      comparison = "COMPARISON_GT"
      duration   = "60s"
    }
  }
  documentation {
    content = "Availability SLO burn for the ${var.istio_services[count.index].service_name} for the past 60m exceeded ${var.istio_services[count.index].availability_burn_rate}x the acceptable budget burn rate. The service is returning less OK responses than desired. Consider viewing the service logs or custom dashboard to retrieve more information or adjust the values for the SLO and error budget."
    mime_type = "text/markdown"
  }
}

# Create another alerting policy, this time on the SLO for latency for the Istio service.
# Alerts on error budget burn rate.
resource "google_monitoring_alert_policy" "istio_service_latency_slo_alert" {
  count = length(var.istio_services)
  display_name = "${var.istio_services[count.index].service_name} Latency Alert Policy"
  combiner     = "AND"
  conditions {
    display_name = "SLO burn rate alert for latency SLO with a threshold of ${var.istio_services[count.index].latency_burn_rate}"
    condition_threshold {
      filter     = "select_slo_burn_rate(\"projects/${var.project_id}/services/ist:${var.project_id}-zone-${var.zone}-cloud-ops-sandbox-default-${var.istio_services[count.index].service_id}/serviceLevelObjectives/${google_monitoring_slo.istio_service_latency_slo[count.index].slo_id}\", 60m)"
      threshold_value = var.istio_services[count.index].availability_burn_rate
      comparison = "COMPARISON_GT"
      duration   = "60s"
    }
  }
  documentation {
    content = "Latency SLO burn for the ${var.istio_services[count.index].service_name} for the past 60m exceeded ${var.istio_services[count.index].latency_burn_rate}x the acceptable budget burn rate. The service is responding slower than desired. Consider viewing the service logs or custom dashboard to retrieve more information or adjust the values for the SLO and error budget."
    mime_type = "text/markdown"
  }
}
