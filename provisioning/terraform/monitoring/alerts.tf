# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

/*
 * Uptime check policy: at least 2 checks failed during 300s
 */
resource "google_monitoring_alert_policy" "frontend_check_alert" {
  display_name = "HTTP Uptime Check Alerting Policy"
  combiner     = "OR"
  conditions {
    display_name = "HTTP Uptime Check Alert"
    condition_threshold {
      filter     = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.label.check_id=\"${google_monitoring_uptime_check_config.frontend_http_check.uptime_check_id}\" AND resource.type=\"uptime_url\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      aggregations {
        # the alignment sets the window over which the metric is viewed
        alignment_period     = "1200s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.*"]
      }
      threshold_value = "2"
      trigger {
        count = "1"
      }
    }
  }
  notification_channels = ["${google_monitoring_notification_channel.email_notification.id}"]
}

/*
 * SLO alert policies: burn rate continues during 60s in window of 1h
 * (requires enable_asm to be `true`)
 */
resource "google_monitoring_alert_policy" "availability_slo_burn_alert" {
  count        = var.enable_asm ? length(local.slo_services) : 0
  display_name = "${local.slo_services[count.index].title} Availability SLO Burn Alert"
  combiner     = "AND"
  conditions {
    display_name = "SLO burn rate alert for availability SLO with a threshold of ${local.burn_rate}"
    condition_threshold {

      # This filter alerts on burn rate over the past 60 minutes
      # The service is defined by the unique Istio string that is automatically created
      filter          = "select_slo_burn_rate(\"${google_monitoring_service.slo_service[count.index].name}/serviceLevelObjectives/${google_monitoring_slo.service_availability[count.index].slo_id}\", 60m)"
      threshold_value = local.burn_rate
      comparison      = "COMPARISON_GT"
      duration        = "60s"
    }
  }
  documentation {
    content   = <<EOT
Availability SLO burn for the ${local.slo_services[count.index].title} for the past 60m
exceeded ${local.burn_rate}x the acceptable budget burn rate. The service is returning
less OK responses than desired. Consider viewing the service logs or custom dashboard
to retrieve more information or adjust the values for the SLO and error budget.
EOT
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "latency_slo_burn_alert" {
  count        = var.enable_asm ? length(local.slo_services) : 0
  display_name = "${local.slo_services[count.index].title} Latency SLO Burn Alert"
  combiner     = "AND"
  conditions {
    display_name = "SLO burn rate alert for latency SLO with a threshold of ${local.burn_rate}"
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_service.slo_service[count.index].name}/serviceLevelObjectives/${google_monitoring_slo.service_latency[count.index].slo_id}\", 60m)"
      threshold_value = local.burn_rate
      comparison      = "COMPARISON_GT"
      duration        = "60s"
    }
  }
  documentation {
    content   = <<EOT
Latency SLO burn for the ${local.slo_services[count.index].title} for the past 60m
exceeded ${local.burn_rate}x the acceptable budget burn rate. The service is responding
slower than desired. Consider viewing the service logs or custom dashboard to retrieve
more information or adjust the values for the SLO and error budget.
EOT
    mime_type = "text/markdown"
  }
}
