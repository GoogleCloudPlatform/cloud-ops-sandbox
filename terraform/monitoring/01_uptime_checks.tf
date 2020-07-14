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

# Here we create a default HTTP Uptime Check on the External IP of our
# Kubernetes cluster revealed by the Load Balancer
# Our uptime check has a period of 1 minute and times out after 10 seconds
resource "google_monitoring_uptime_check_config" "http" {
  display_name = "HTTP Uptime Check"
  timeout      = "10s"
  period       = "60s"  

  http_check {
    path = "/"
    port = "80"
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = "${var.project_id}"
      host       = "${var.external_ip}"
    }
  }
}

# Here we place an alerting policy on the HTTP Uptime Check that alerts based on
# failed uptime checks. The alerting policy will be triggered if the uptime check
# fails more than 1 time over a 1 minute period aligned over 20 minutes.
# 
# Our alerting policy notifies errors via email
resource "google_monitoring_alert_policy" "alert_policy" {
  display_name = "HTTP Uptime Check Alerting Policy"
  combiner     = "OR"
  conditions {
    display_name = "HTTP Uptime Check Alert"
    condition_threshold {
      filter     = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.label.check_id=\"${google_monitoring_uptime_check_config.http.uptime_check_id}\" AND resource.type=\"uptime_url\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period   = "1200s"
        per_series_aligner = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields = ["resource.label.*"]
      }
      threshold_value = "1"
      trigger {
        count = "1"
      }
    }
  }
  notification_channels = ["${google_monitoring_notification_channel.basic.id}"]
}

# Here we configure the email notification channel for the HTTP uptime check 
# alerting policy. The email configured is the email of the owner of the project.
resource "google_monitoring_notification_channel" "basic" {
  display_name = "Google Project Owner Account Email"
  type         = "email"
  labels = {
    email_address = "${var.project_owner_email}"
  }
}
