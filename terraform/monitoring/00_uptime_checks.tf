provider "google" {
  # pin provider to 2.x
  version = "~> 2.1"

  # credentials = "/path/to/creds.json"
  # project = "project-id"
  # region = "default-region"
  # zone = "default-zone"
}

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
  #notification_channels = ["${google_monitoring_notification_channel.basic.id}"]
}

resource "google_service_account" "service_account" {
  account_id = "sandbox-service-account"
  display_name = "Service Account"
}

resource "google_monitoring_notification_channel" "basic" {
  display_name = "Google Service Account Email"
  type         = "email"
  labels = {
    email_address = "${google_service_account.service_account.email}"
  }
}
