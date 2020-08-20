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

# Create an SLO for availablity for the custom service.
# Example SLO is defined as following:
#   90% of all non-4XX requests within the past 30 day windowed period
#   return with 200 OK status
resource "google_monitoring_slo" "custom_service_availability_slo" {
  count = length(var.custom_services)
  service = google_monitoring_custom_service.custom_service[count.index].service_id
  slo_id = "availability-slo"
  display_name = "Availability SLO with request base SLI (good total ratio)"

  # The goal sets our objective for successful requests over the 30 day rolling window period
  goal = var.custom_services[count.index].availability_goal
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
# Example SLO is defined as following:
#   90% of requests that return 200 OK responses return in under 500 ms
resource "google_monitoring_slo" "custom_service_latency_slo" {
  count = length(var.custom_services)
  service = google_monitoring_custom_service.custom_service[count.index].service_id
  slo_id = "latency-slo"
  display_name = "Latency SLO with request base SLI (distribution cut)"

  goal = var.custom_services[count.index].latency_goal
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

# Create an SLO for availablity for the Istio service.
# Example SLO is defined as following:
#   90% of all non-4XX requests within the past 30 day windowed period
#   return with 200 OK status
resource "google_monitoring_slo" "istio_service_availability_slo" {
  count = length(var.istio_services)

  # Uses the Istio service that is automatically detected and created by installing Istio
  # Identify the service using the string: ist:${project_id}-zone-${zone}-cloud-ops-sandbox-default-${service_id}
  service = "ist:${var.project_id}-zone-${var.zone}-cloud-ops-sandbox-default-${var.istio_services[count.index].service_id}"
  slo_id = "availability-slo"
  display_name = "Availability SLO with request base SLI (good total ratio)"

  # The goal sets our objective for successful requests over the 30 day rolling window period
  goal = var.istio_services[count.index].availability_goal
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
#   99% of requests that return 200 OK responses return in under 500 ms
resource "google_monitoring_slo" "istio_service_latency_slo" {
  count = length(var.istio_services)
  service = "ist:${var.project_id}-zone-${var.zone}-cloud-ops-sandbox-default-${var.istio_services[count.index].service_id}"
  slo_id = "latency-slo"
  display_name = "Latency SLO with request base SLI (distribution cut)"

  goal = var.istio_services[count.index].latency_goal
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