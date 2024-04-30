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

locals {
  namespace         = "default"
  burn_rate         = 2    # (2x factor)
  latency_threshold = 1000 # (ms)
  slo_services = [
    {
      title = "Frontend Service"
      id    = "frontend"
    },
    {
      title = "Checkout Service"
      id    = "checkoutservice"
    },
    {
      title = "Payment Service"
      id    = "paymentservice"
    },
    {
      title = "Email Service"
      id    = "emailservice"
    },
    {
      title = "Shipping Service"
      id    = "shippingservice"
    },
    {
      title = "Cart Service"
      id    = "cartservice"
    },
    {
      title = "Product Catalog Service"
      id    = "productcatalogservice"
    },
    {
      title = "Currency Service"
      id    = "currencyservice"
    },
    {
      title = "Recommendation Service"
      id    = "recommendationservice"
    },
    {
      title = "Ad Service"
      id    = "adservice"
    }
  ]
  slo_goal = 0.9 # (common goal of 90%)
}

resource "google_monitoring_service" "slo_service" {
  count = var.enable_asm ? length(local.slo_services) : 0

  service_id   = "${local.slo_services[count.index].id}${var.name_suffix}"
  display_name = local.slo_services[count.index].title

  user_labels = {
    creator = "Cloud Ops Sandbox"
  }

  basic_service {
    service_type = "CLUSTER_ISTIO"
    service_labels = {
      location : var.gke_cluster_location,
      cluster_name : var.gke_cluster_name,
      service_namespace : local.namespace,
      service_name : local.slo_services[count.index].id
    }
  }
}

resource "google_monitoring_slo" "service_availability" {
  count        = var.enable_asm ? length(local.slo_services) : 0
  service      = google_monitoring_service.slo_service[count.index].service_id
  slo_id       = "${local.slo_services[count.index].id}-availability-slo${var.name_suffix}"
  display_name = "${local.slo_goal * 100}% - Availability - Rolling 30 Days - ${local.slo_services[count.index].id}"

  # The goal sets our objective for successful requests over the 30 day rolling window period
  goal                = local.slo_goal
  rolling_period_days = 30

  basic_sli {
    availability {
      enabled = "true"
    }
  }
}

resource "google_monitoring_slo" "service_latency" {
  count               = var.enable_asm ? length(local.slo_services) : 0
  service             = google_monitoring_service.slo_service[count.index].service_id
  slo_id              = "${local.slo_services[count.index].id}-latency-slo${var.name_suffix}"
  display_name        = "${local.slo_goal * 100}% - Latency - Rolling 30 days - ${local.slo_services[count.index].id}"
  goal                = local.slo_goal
  rolling_period_days = 30

  request_based_sli {
    distribution_cut {
      # include latencies from requests that respond 200
      distribution_filter = join(" AND ", [
        "metric.type=\"istio.io/service/server/response_latencies\"",
        "resource.type=\"k8s_container\"",
        "resource.label.\"cluster_name\"=\"${var.gke_cluster_name}\"",
        "metric.label.\"response_code\"=\"200\"",
        "metadata.user_labels.\"app\"=\"${local.slo_services[count.index].id}\""
      ])

      range {
        # omitted min value means -infinity
        max = local.latency_threshold
      }
    }
  }
}
