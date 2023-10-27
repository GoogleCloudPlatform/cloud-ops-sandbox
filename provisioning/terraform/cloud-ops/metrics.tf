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


resource "google_logging_metric" "metrics" {
  for_each    = { for m in local.metrics_raw_data.metrics : m.name => local.metrics[m.name] }
  name        = "${each.key}_${var.name_suffix}"
  filter      = each.value.filter
  bucket_name = try(each.value.bucket_name, null)
  dynamic "metric_descriptor" {
    for_each = can(each.value.metric_descriptor) ? toset([1]) : toset([])
    content {
      metric_kind = try(each.value.metric_descriptor.kind, "DELTA")
      value_type  = try(each.value.metric_descriptor.value_type, "INT64")
      unit        = try(each.value.metric_descriptor.unit, "1")
      dynamic "labels" {
        for_each = can(each.value.labels) ? { for l in each.value.labels : l.key => l } : {}
        content {
          key         = labels.value.key
          description = try(labels.value.description, null)
          value_type  = try(labels.value.value_type, "STRING")
        }
      }
    }
  }
  value_extractor  = try(each.value.extractor, null)
  label_extractors = can(each.value.labels) ? { for l in each.value.labels : l.key => l.extractor } : {}
}
