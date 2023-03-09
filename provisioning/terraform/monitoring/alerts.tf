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

resource "google_monitoring_notification_channel" "email_notification" {
  display_name = "ACME DevOps department"
  type         = "email"
  labels = {
    email_address = var.notification_channel_email
  }
}

# Notify via email if during last 5 minutes at least 2 frontend health checks failed
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
