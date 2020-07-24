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

# Create an alerting policy on the Availability SLO for the frontend service.
# The definition of the SLO can be found in the file '03_service_slo.tf'.
# We alert on budget burn rate, alerting if burn rate exceeds twice the allotted burn rate
# within the past hour. 
resource "google_monitoring_alert_policy" "frontend_availability_slo_alert" {
  display_name = "Frontend Service Availability Alert Policy"
  combiner     = "AND"
  conditions {
    display_name = "SLO burn rate alert for availability SLO with a threshold of 2"
    condition_threshold {

      # This filter alerts on burn rate over the past 60 minutes
      filter     = "select_slo_burn_rate(\"projects/${var.project_id}/services/${google_monitoring_custom_service.frontend.service_id}/serviceLevelObjectives/${google_monitoring_slo.frontend_availability_slo.slo_id}\", 60m)"
      
      # The threshhold is determined by how quickly we burn through our error budget, and we alert if we will use our error budget within 15 days.
      # Details: https://landing.google.com/sre/workbook/chapters/alerting-on-slos/#4-alert-on-burn-rate 
      threshold_value = "2"
      comparison = "COMPARISON_GT"
      duration   = "60s"
    }
  }
  documentation {
    content = "Availability SLO burn for the frontend service for the past 60m exceeded twice the acceptable budget burn rate. The service is returning less OK responses than desired. Consider viewing the service logs or custom dashboard to retrieve more information or adjust the values for the SLO and error budget."
    mime_type = "text/markdown"
  }
}

# Create another alerting policy, this time on the SLO for latency for the frontend service.
# Again we alert on error budget burn rate, alerting if we burn more than twice our allotted budget within
# the past 60 minutes.
resource "google_monitoring_alert_policy" "frontend_latency_slo_alert" {
  display_name = "Frontend Service Latency Alert Policy"
  combiner     = "AND"
  conditions {
    display_name = "SLO burn rate alert for latency SLO with a threshold of 2"
    condition_threshold {
      filter     = "select_slo_burn_rate(\"projects/${var.project_id}/services/${google_monitoring_custom_service.frontend.service_id}/serviceLevelObjectives/${google_monitoring_slo.frontend_latency_slo.slo_id}\", 60m)"
      threshold_value = "2"
      comparison = "COMPARISON_GT"
      duration   = "60s"
    }
  }
  documentation {
    content = "Latency SLO burn for the frontend service for the past 60m exceeded twice the acceptable budget burn rate. The service is responding slower than desired. Consider viewing the service logs or custom dashboard to retrieve more information or adjust the values for the SLO and error budget."
    mime_type = "text/markdown"
  }
}
