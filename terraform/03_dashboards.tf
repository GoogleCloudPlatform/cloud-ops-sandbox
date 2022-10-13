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
  dashboards_config = yamldecode(templatefile("${var.cfg_file_location}/dashboards.yaml", { project_id = var.project_id }))
  dashboards = {
    for dashboard in local.dashboards_config.dashboards : dashboard.name => dashboard
  }
  log_based_metrics = {
    for metric in local.dashboards_config.log_based_metrics : metric.name => metric
  }
}

resource "google_logging_metric" "log_based_metrics" {
  for_each = local.log_based_metrics
  name     = "${each.value.name}${var.state_suffix}"
  filter   = each.value.filter
  metric_descriptor {
    metric_kind = each.value.kind
    value_type  = each.value.type
    unit        = try(each.value.unit, null)
    dynamic "labels" {
      for_each = try(each.value.labels, {})
      content {
        key         = labels.key
        description = try(labels.value.description, "")
        value_type  = try(labels.value.type, "STRING")
      }
    }
    display_name = each.value.display_name
  }
  # Regex extractor has matching group to match the product name or product id. Example: orderedItem="Terrarium", id="L9ECAV7KIM" 
  # matches Terrarium for product name and L9ECAV7KIM for product id.
  label_extractors = { for k, v in each.value.labels : k => v.extractor }
}

resource "google_monitoring_dashboard" "dashboards" {
  for_each       = local.dashboards
  dashboard_json = templatefile("templates/dashboard.tftpl", each.value)
}
