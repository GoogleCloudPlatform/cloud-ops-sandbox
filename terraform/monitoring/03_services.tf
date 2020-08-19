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

# Define specifics for each of the services that will receive SLOs through a custom service
# The data members needed are to specify the custom service, goals for each SLO (availability and latency),
# and maximum error budget burn rates.
variable "custom_services" {
  type = list(object({
    service_name = string,
    service_id = string,
    availability_goal = number,
    availability_burn_rate = number,
    latency_goal = number,
    latency_threshold = number,
    latency_burn_rate = number
  }))
  default = [
    {
      service_name = "Frontend Service"
      service_id = "frontend"
      availability_goal = 0.9		# configurable goal for the availability SLO (0.9 = 90% of requests are successsful)
      availability_burn_rate = 2	# limit on error budget burn rate (2 indicates we alert if error budget is consumed 2x faster than it should)
      latency_goal = 0.9			# configurable goal for the latency SLO (0.9 = 90% of requests finish in under the latency threshold)
      latency_threshold = 500		# indicates 500ms as the maximum latency of a 'good' request
      latency_burn_rate = 2
    },
    {
      service_name = "Checkout Service"
      service_id = "checkoutservice"
      availability_goal = 0.99
      availability_burn_rate = 2
      latency_goal = 0.99
      latency_threshold = 500
      latency_burn_rate = 2
    },
    {
      service_name = "Payment Service"
      service_id = "paymentservice"
      availability_goal = 0.99
      availability_burn_rate = 2
      latency_goal = 0.99
      latency_threshold = 500
      latency_burn_rate = 2
    },
    {
      service_name = "Email Service"
      service_id = "emailservice"
      availability_goal = 0.99
      availability_burn_rate = 2
      latency_goal = 0.99
      latency_threshold = 500
      latency_burn_rate = 2
    },
    {
      service_name = "Shipping Service"
      service_id = "shippingservice"
      availability_goal = 0.99
      availability_burn_rate = 2
      latency_goal = 0.99
      latency_threshold = 500
      latency_burn_rate = 2
    }
  ]
}

# Create a custom service that we attach our SLOs to
# Using a custom service here allows us to add on additional SLOs and 
# alerting policies on things such as custom metrics.
#
# There is the option to use an Istio service since Istio automatically detects and creates 
# services for us. This example uses a custom service to demonstrate Terraform support for 
# creating custom services with attached SLOs and alerting policies.
resource "google_monitoring_custom_service" "custom_service" {
  count = length(var.custom_services)
  service_id = "${var.custom_services[count.index].service_id}-srv"
  display_name = var.custom_services[count.index].service_name
}
