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

# Create an SLO for availability for the custom service.
# For all services other than Frontend SLO is defined as following:
#   99% of HTTP requests are successful within the past 30 day windowed period
# For the Frontend service SLO is defined as following:
#   90% of HTTP requests are successful within the past 30 day windowed period

resource "google_monitoring_slo" "custom_service_availability_slo" {
  count        = length(var.custom_services)
  service      = google_monitoring_custom_service.custom_service[count.index].service_id
  slo_id       = "${google_monitoring_custom_service.custom_service[count.index].service_id}-availability-slo"
  display_name = "Availability SLO with request base SLI (good total ratio) for ${google_monitoring_custom_service.custom_service[count.index].service_id}"

  # The goal sets our objective for successful requests over the 30 day rolling window period
  goal                = var.custom_services[count.index].availability_goal
  rolling_period_days = 30

  request_based_sli {
    good_total_ratio {

      # The "good" service is the number of 200 OK responses
      good_service_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/request_count\"",
        "resource.type=\"k8s_container\"",
        "resource.label.\"cluster_name\"=\"cloud-ops-sandbox\"",
        "metadata.user_labels.\"app\"=\"${var.custom_services[count.index].service_id}\"",
        "metric.label.\"response_code\"=\"200\""
      ])

      # The total is the number of non-4XX responses
      # We eliminate 4XX responses since they do not accurately represent server-side 
      # failures and have the possibility of skewing our SLO measurements
      total_service_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/request_count\"",
        "resource.type=\"k8s_container\"",
        "resource.label.\"cluster_name\"=\"cloud-ops-sandbox\"",
        "metadata.user_labels.\"app\"=\"${var.custom_services[count.index].service_id}\"",
        join(" OR ", ["metric.label.\"response_code\"<\"400\"",
        "metric.label.\"response_code\">=\"500\""])
      ])

    }
  }
}

# Create another SLO on the custom service this time with respect to latency.
# For all services other than Frontend SLO is defined as following:
#   99% of requests return in under 500 ms in the previous 30 days
# For the Frontend service SLO is defined as following:
#   90% of requests return in under 500 ms in the previous 30 days
resource "google_monitoring_slo" "custom_service_latency_slo" {
  count        = length(var.custom_services)
  service      = google_monitoring_custom_service.custom_service[count.index].service_id
  slo_id       = "${google_monitoring_custom_service.custom_service[count.index].service_id}-latency-slo"
  display_name = "Latency SLO with request base SLI (distribution cut) for ${google_monitoring_custom_service.custom_service[count.index].service_id}"

  goal                = var.custom_services[count.index].latency_goal
  rolling_period_days = 30

  request_based_sli {
    distribution_cut {

      # The distribution filter retrieves latencies of requests that returned 200 OK responses
      distribution_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/response_latencies\"",
        "resource.type=\"k8s_container\"",
        "resource.label.\"cluster_name\"=\"cloud-ops-sandbox\"",
        "metric.label.\"response_code\"=\"200\"",
        "metadata.user_labels.\"app\"=\"${var.custom_services[count.index].service_id}\""
      ])

      range {

        # By not setting a min value, it is automatically set to -infinity
        # The units of the upper bound is in ms
        max = var.custom_services[count.index].latency_threshold

      }
    }
  }
}

# Create an SLO for availability for the Istio service.
# Example SLO is defined as following:
#   90% of HTTP requests are successful within the past 30 day windowed period
resource "google_monitoring_slo" "istio_service_availability_slo" {
  # Uses the Istio service that is automatically detected and created by installing Istio
  # Identify the service using the string: canonical-ist:proj-${project_number}-default-${istio_services[count.index].service_id}
  count        = length(var.istio_services)
  service      = "canonical-ist:proj-${var.project_number}-default-${var.istio_services[count.index].service_id}"
  slo_id       = "${var.istio_services[count.index].service_id}-availability-slo"
  display_name = "Availability SLO with request base SLI (good total ratio) for ${var.istio_services[count.index].service_id}"

  # The goal sets our objective for successful requests over the 30 day rolling window period
  goal                = var.istio_services[count.index].availability_goal
  rolling_period_days = 30

  request_based_sli {
    good_total_ratio {

      # The "good" service is the number of 200 OK responses
      good_service_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/request_count\"",
        "resource.type=\"k8s_container\"",
        "resource.label.\"cluster_name\"=\"cloud-ops-sandbox\"",
        "metadata.user_labels.\"app\"=\"${var.istio_services[count.index].service_id}\"",
        "metric.label.\"response_code\"=\"200\""
      ])

      # The total is the number of non-4XX responses
      # We eliminate 4XX responses since they do not accurately represent server-side 
      # failures and have the possibility of skewing our SLO measurements
      total_service_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/request_count\"",
        "resource.type=\"k8s_container\"",
        "resource.label.\"cluster_name\"=\"cloud-ops-sandbox\"",
        "metadata.user_labels.\"app\"=\"${var.istio_services[count.index].service_id}\"",
        join(" OR ", ["metric.label.\"response_code\"<\"400\"",
        "metric.label.\"response_code\">=\"500\""])
      ])

    }
  }
}

# Create an SLO with respect to latency using the Istio service.
# Example SLO is defined as:
#   99% of requests return in under 500 ms in the previous 30 days
resource "google_monitoring_slo" "istio_service_latency_slo" {
  count               = length(var.istio_services)
  service             = "canonical-ist:proj-${var.project_number}-default-${var.istio_services[count.index].service_id}"
  slo_id              = "${var.istio_services[count.index].service_id}-latency-slo"
  display_name        = "Latency SLO with request base SLI (distribution cut) for ${var.istio_services[count.index].service_id}"
  goal                = var.istio_services[count.index].latency_goal
  rolling_period_days = 30

  request_based_sli {
    distribution_cut {

      # The distribution filter retrieves latencies of requests that returned 200 OK responses
      distribution_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/response_latencies\"",
        "resource.type=\"k8s_container\"",
        "resource.label.\"cluster_name\"=\"cloud-ops-sandbox\"",
        "metric.label.\"response_code\"=\"200\"",
        "metadata.user_labels.\"app\"=\"${var.istio_services[count.index].service_id}\""
      ])

      range {
        # By not setting a min value, it is automatically set to -infinity
        # The upper bound for latency is in ms
        max = var.istio_services[count.index].latency_threshold

      }
    }
  }
}

# Rating service availability SLO:
#   99% of HTTP requests are successful within the past 30 day windowed period

resource "google_monitoring_slo" "rating_service_availability_slo" {
  # Uses ratingservice service that is automatically detected and created when the service is deployed to App Engine
  # Identify of the service is built after the following template: gae:${project_id}_servicename
  count        = var.skip_ratingservice ? 0 : 1
  service      = "gae:${var.project_id}_ratingservice"
  slo_id       = "ratingservice-availability-slo"
  display_name = "Rating Service Availability SLO with request base SLI (good total ratio)"

  # The goal sets our objective for successful requests over the 30 day rolling window period
  goal                = 0.99
  rolling_period_days = 30

  request_based_sli {
    good_total_ratio {

      # The "good" service is the number of 200 OK responses
      good_service_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_count\"",
        "resource.type=\"gae_app\"",
        "resource.label.\"version_id\"=\"prod\"",
        "resource.label.\"module_id\"=\"ratingservice\"",
        "metric.label.\"loading\"=\"false\"",
        "metric.label.\"response_code\"=\"200\""
      ])

      # The total is the number of non-4XX and 429 (Too Many Requests) responses
      # We eliminate 4XX responses except 429 (Too Many Requests) since they do not accurately represent server-side 
      # failures and have the possibility of skewing our SLO measurements
      total_service_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_count\"",
        "resource.type=\"gae_app\"",
        "resource.label.\"version_id\"=\"prod\"",
        "resource.label.\"module_id\"=\"ratingservice\"",
        "metric.label.\"loading\"=\"false\"",
        # a mix of 'AND' and 'OR' operators is not currently supported
        # without the following filter responses with HTTP status [400,500) will be included
        # while a general guideline to exclude them since they do not reflect service issues
        # join(" OR ", ["metric.label.\"response_code\"<\"400\"",
        #   "metric.label.\"response_code\"=\"429\"",
        # "metric.label.\"response_code\">=\"500\""])
      ])
    }
  }
}

# Rating service latency SLO:
#   99% of requests that return in under 175 ms in the previous 30 days

resource "google_monitoring_slo" "rating_service_latency_slo" {
  # Uses ratingservice service that is automatically detected and created when the service is deployed to App Engine
  # Identify of the service is built after the following template: gae:${project_id}_servicename
  count        = var.skip_ratingservice ? 0 : 1
  service      = "gae:${var.project_id}_ratingservice"
  slo_id       = "ratingservice-latency-slo"
  display_name = "Rating Service Latency SLO with request base SLI (distribution cut)"

  goal                = 0.99
  rolling_period_days = 30

  request_based_sli {
    distribution_cut {

      # The distribution filter retrieves latencies of user requests that returned 200 OK responses
      distribution_filter = join(" AND ", [
        "metric.type=\"appengine.googleapis.com/http/server/response_latencies\"",
        "resource.type=\"gae_app\"",
        "resource.label.\"version_id\"=\"prod\"",
        "resource.label.\"module_id\"=\"ratingservice\"",
        "metric.label.\"loading\"=\"false\"",
        "metric.label.\"response_code\"=\"200\"",
      ])

      range {
        # By not setting a min value, it is automatically set to -infinity
        # The upper bound for latency is in ms
        max = 500
      }
    }
  }
}

# Rating service's data freshness SLO:
# during a day 99.9% of minutes have at least 1 successful recollect API call
resource "google_monitoring_slo" "rating_service_freshness_slo" {
  # Uses ratingservice service that is automatically detected and created when the service is deployed to App Engine
  # Identify of the service is built after the following template: gae:${project_id}_servicename
  count        = var.skip_ratingservice ? 0 : 1
  service      = "gae:${var.project_id}_ratingservice"
  slo_id       = "ratingservice-freshness-slo"
  display_name = "Rating freshness SLO with window based SLI"

  goal                = 0.99
  rolling_period_days = 1

  windows_based_sli {
    window_period = "60s"
    metric_sum_in_range {
      time_series = join(" AND ", [
        "metric.type=\"logging.googleapis.com/user/ratingservice_recollect_requests_count\"",
        "resource.type=\"gae_app\"",
        join(" OR ", ["metric.label.\"status\"<\"400\"",
        "metric.label.\"status\"=\"429\""])
      ])
      range {
        min = 1
        max = 9999 # the maximum can be any number of requests; the unreasonably high value is placed since inf is not supported
      }
    }
  }

  depends_on = [google_logging_metric.ratingservice_logging_metric]
}
