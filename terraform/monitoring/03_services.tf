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

# Specify services that will use the Istio service that is automatically detected
# and created by installing Istio on the Kubernetes cluster.
# The data members required are to successfully set up SLOs (goals and latency thresholds)
# and burn rate limits for alerting policies
variable "istio_services" {
  type = list(object({
    service_name           = string,
    service_id             = string,
    availability_goal      = number,
    availability_burn_rate = number,
    latency_goal           = number,
    latency_threshold      = number,
    latency_burn_rate      = number
  }))
  default = [
    {
      service_name           = "Frontend Service"
      service_id             = "frontend"
      availability_goal      = 0.9 # configurable goal for the availability SLO (0.9 = 90% of requests are successsful)
      availability_burn_rate = 2   # limit on error budget burn rate (2 indicates we alert if error budget is consumed 2x faster than it should)
      latency_goal           = 0.9 # configurable goal for the latency SLO (0.9 = 90% of requests finish in under the latency threshold)
      latency_threshold      = 1500 # indicates 1000ms as the maximum latency of a 'good' request
      latency_burn_rate      = 2
    },
    {
      service_name           = "Checkout Service"
      service_id             = "checkoutservice"
      availability_goal      = 0.9
      availability_burn_rate = 2
      latency_goal           = 0.9
      latency_threshold      = 1000
      latency_burn_rate      = 2
    },
    {
      service_name           = "Payment Service"
      service_id             = "paymentservice"
      availability_goal      = 0.9
      availability_burn_rate = 2
      latency_goal           = 0.9
      latency_threshold      = 1000
      latency_burn_rate      = 2
    },
    {
      service_name           = "Email Service"
      service_id             = "emailservice"
      availability_goal      = 0.9
      availability_burn_rate = 2
      latency_goal           = 0.9
      latency_threshold      = 1000
      latency_burn_rate      = 2
    },
    {
      service_name           = "Shipping Service"
      service_id             = "shippingservice"
      availability_goal      = 0.9
      availability_burn_rate = 2
      latency_goal           = 0.9
      latency_threshold      = 1000
      latency_burn_rate      = 2
    },
    {
      service_name           = "Cart Service"
      service_id             = "cartservice"
      availability_goal      = 0.9
      availability_burn_rate = 2
      latency_goal           = 0.9
      latency_threshold      = 1000
      latency_burn_rate      = 2
    },
    {
      service_name           = "Product Catalog Service"
      service_id             = "productcatalogservice"
      availability_goal      = 0.9
      availability_burn_rate = 2
      latency_goal           = 0.9
      latency_threshold      = 1000
      latency_burn_rate      = 2
    },
    {
      service_name           = "Currency Service"
      service_id             = "currencyservice"
      availability_goal      = 0.9
      availability_burn_rate = 2
      latency_goal           = 0.9
      latency_threshold      = 1000
      latency_burn_rate      = 2
    },
    {
      service_name           = "Recommendation Service"
      service_id             = "recommendationservice"
      availability_goal      = 0.9
      availability_burn_rate = 2
      latency_goal           = 0.9
      latency_threshold      = 1000
      latency_burn_rate      = 2
    },
    {
      service_name           = "Ad Service"
      service_id             = "adservice"
      availability_goal      = 0.9
      availability_burn_rate = 2
      latency_goal           = 0.9
      latency_threshold      = 500
      latency_burn_rate      = 2
    }
  ]
}
