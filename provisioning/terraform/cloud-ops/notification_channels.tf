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

resource "google_monitoring_notification_channel" "notification_channels" {
  for_each     = { for c in local.alerts_raw_data.channels : "${c.name}_${var.name_suffix}" => local.notificatin_channels[c.name] }
  display_name = each.value.display_name
  type         = each.value.type
  labels       = each.value.labels
}
