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
  alerts_config = yamldecode(templatefile("${locals.validated_configuration_path}/alerts.yaml", local.template_vars))
  alerts = {
    for alert in local.alerts_config.alerts : alert.name => alert
  }
  channels = {
    for channel in local.alerts_config.channels : channel.name => channel
  }
}

resource "google_monitoring_notification_channel" "channels" {
  for_each     = local.channels
  display_name = each.value.display-name
  type         = each.value.type
  labels       = each.value.labels
}

resource "google_monitoring_alert_policy" "alerts" {
  for_each     = local.alerts
  display_name = each.value.display_name
  combiner     = each.value.combiner
  documentation {
    content   = each.value.documentation != null ? each.value.documentation : ""
    mime_type = "text/markdown"
  }
  notification_channels = (each.value.notification-channels != null ?
    each.value.notification-channels : []
  )
  dynamic "conditions" {
    for_each = each.value.conditions
    content {
      filter          = each.value.condition.filter
      threshold_value = each.value.condition.threshold
      comparison      = each.value.condition.comparison
      duration        = each.value.condition.duration
    }
  }
  # only threshold condition is supported
  condition_threshold {
    filter          = each.value.condition.filter
    threshold_value = each.value.condition.threshold
    comparison      = each.value.condition.comparison
    duration        = each.value.condition.duration
  }
  depends_on = [google_monitoring_slo.service_slos, google_monitoring_uptime_check_config.uptime_checks]
}
