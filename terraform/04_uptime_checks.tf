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
  ut_checks_config = yamldecode(templatefile("${var.cfg_file_location}/uptime_checks.yaml", local.config_file_subsitutes))
  ut_checks = {
    for c in local.ut_checks_config.checks : c.name => c
  }
}

resource "google_monitoring_uptime_check_config" "uptime_checks" {
  for_each     = local.ut_checks
  display_name = each.value.display_name
  timeout      = each.value.timeout
  period       = each.value.period
  dynamic "content_matchers" {
    for_each = can(each.value.content_matcher) ? toset([1]) : toset([])
    content {
      content = each.value.content_matcher.content
      matcher = try(each.value.content_matcher.matcher, "CONTAINS_STRING")
    }
  }
  http_check {
    path = each.value.http_check.path
  }
  dynamic "monitored_resource" {
    for_each = can(each.value.resource) ? toset([1]) : toset([])
    content {
      type   = each.value.resource.type
      labels = each.value.resource.labels
    }
  }
}
