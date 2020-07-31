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

# Create a custom service that we attach our SLOs to
# Using a custom service here allows us to add on additional SLOs and 
# alerting policies on things such as custom metrics.
#
# There is the option to use an Istio service since Istio automatically detects and creates 
# services for us. This example uses a custom service to demonstrate Terraform support for 
# creating custom services with attached SLOs and alerting policies.
resource "google_monitoring_custom_service" "frontend" {
  service_id = "frontend-srv"
  display_name = "Frontend Service"
}

# Create an SLO for availablity for the frontend service.
# The SLO is defined as following: 
#   80% of all non-4XX requests within the past 30 day windowed period
#   return with 200 OK status
resource "google_monitoring_slo" "frontend_availability_slo" {
  service = google_monitoring_custom_service.frontend.service_id
  slo_id = "availability-slo"
  display_name = "Availability SLO with request base SLI (good total ratio)"

  # The goal sets our 80% objective with a 30 day rolling window period
  # NOTE: An 80% SLO is not meant to be exemplary of best practice, but it is used for educational
  # purposes. The value can be modified to see its impacts on error budget.
  goal = 0.8
  rolling_period_days = 30

  request_based_sli {
    good_total_ratio {

      # The "good" service is the number of 200 OK responses
      good_service_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/request_count\"",
        "resource.type=\"k8s_container\"",
        "resource.label.\"cluster_name\"=\"stackdriver-sandbox\"",
        "metadata.user_labels.\"app\"=\"frontend\"",
        "metric.label.\"response_code\"=\"200\""
      ])

      # The total is the number of non-4XX responses
      # We elimiate 4XX responses since they do not accurately represent server-side 
      # failures and have the possibility of skewing our SLO measurements
      total_service_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/request_count\"",
        "resource.type=\"k8s_container\"",
        "resource.label.\"cluster_name\"=\"stackdriver-sandbox\"",
        "metadata.user_labels.\"app\"=\"frontend\"",
        join(" OR ", ["metric.label.\"response_code\"<\"400\"",
          "metric.label.\"response_code\">=\"500\""])
      ])
      
    }
  }
}

# Create another SLO on the frontend service this time with respect to latency.
# Our SLO is defined as following:
#   80% of requests that return 200 OK responses return in under 500 ms
resource "google_monitoring_slo" "frontend_latency_slo" {
  service = google_monitoring_custom_service.frontend.service_id
  slo_id = "latency-slo"
  display_name = "Latency SLO with request base SLI (distribution cut)"

  # Again we set our goal of 80% with a 30 day rolling window period.
  goal = 0.8
  rolling_period_days = 30

  request_based_sli {
    distribution_cut {

      # The distribution filter retrieves latencies of requests that returned 200 OK responses
      distribution_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/response_latencies\"",
        "resource.type=\"k8s_container\"",
        "resource.label.\"cluster_name\"=\"stackdriver-sandbox\"",
        "metric.label.\"response_code\"=\"200\"",
        "metadata.user_labels.\"app\"=\"frontend\""
      ])

      range {

        # By not setting a min value, it is automatically set to -infinity
        # The upper bound for latency is 500 ms
        max = 500

      }
    }
  }
}
