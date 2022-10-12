# Copyright 2020 Google LLC
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
  alerts_config = yamldecode(templatefile("${var.cfg_file_location}/alerts.yaml", { project_id = var.project_id }))
  alerts = {
    for p in local.alerts_config.alerts : p.name => p
  }
}

resource "google_monitoring_alert_policy" "alerts" {
  for_each     = local.alerts
  display_name = each.value.display_name
  # only one condition is supported
  combiner = "AND"
  conditions {
    display_name = each.value.display_name
    # only threshold condition is supported
    condition_threshold {
      filter          = each.value.condition.filter
      threshold_value = each.value.condition.threshold
      comparison      = each.value.condition.comparison
      duration        = each.value.condition.duration
    }
  }
  documentation {
    content   = each.value.documentation.content
    mime_type = "text/markdown"
  }
  depends_on = [google_monitoring_slo.service_slos, google_monitoring_uptime_check_config.uptime_checks]
}
