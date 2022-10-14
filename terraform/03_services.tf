# Copyright 2022 Google LLC
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
  services_config = yamldecode(templatefile("${var.cfg_file_location}/services.yaml", local.config_file_subsitutes))
  service_slos = {
    for slo in local.services_config.service_slos : slo.name => slo
  }
}

resource "google_monitoring_slo" "service_slos" {
  for_each            = local.service_slos
  slo_id              = "${each.value.name}${local.name_suffix}"
  display_name        = each.value.display_name
  service             = each.value.service
  goal                = tonumber(each.value.goal)
  calendar_period     = try(each.value.calendar_period, null)
  rolling_period_days = try(each.value.rolling_period_days, null)
  dynamic "basic_sli" {
    for_each = can(each.value.basic_sli) ? toset([1]) : toset([])
    content {
      dynamic "latency" {
        for_each = can(each.value.basic_sli.latency) ? toset([1]) : toset([])
        content {
          threshold = each.value.basic_sli.latency.threshold
        }
      }
      dynamic "availability" {
        for_each = can(each.value.basic_sli.availability) ? toset([1]) : toset([])
        content {
          enabled = true
        }
      }
    }
  }
}
