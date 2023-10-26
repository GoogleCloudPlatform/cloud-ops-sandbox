# Copyright 2023 Google LLC
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


resource "google_monitoring_uptime_check_config" "uptime_checks" {
  for_each     = { for c in local.uptimechecks_raw_data.checks : "${c.name}_${var.name_suffix}" => local.uptimechecks[c.name] }
  display_name = each.value.display-name
  timeout      = each.value.timeout
  period       = try(each.value.period, "300s")
  dynamic "content_matchers" {
    for_each = can(each.value.content) ? toset([1]) : toset([])
    content {
      content = each.value.content.content
      matcher = try(each.value.content.matcher, "CONTAINS_STRING")
    }
  }
  http_check {
    path = startswith(each.value.http_check.path, "/") ? each.value.http_check.path : "/${each.value.http_check.path}"
  }
  dynamic "monitored_resource" {
    for_each = can(each.value.resource) ? toset([1]) : toset([])
    content {
      type   = each.value.resource.type
      labels = each.value.resource.labels
    }
  }
}
