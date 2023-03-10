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

resource "google_logging_metric" "checkoutservice_logging_metric" {
  name   = "checkoutservice_log_metric${var.name_suffix}"
  filter = "resource.type=k8s_container AND resource.labels.cluster_name=${var.gke_cluster_name} AND resource.labels.namespace_name=${var.manifest_namespace} AND resource.labels.container_name=server AND orderedItem"
  metric_descriptor {
    metric_kind = "DELTA" # set to DELTA for counter-based metric
    value_type  = "INT64" # set to INT64 for counter-based metric
    unit        = "1"
    labels {
      key         = "product_name"
      description = "Filters by Product Name"
    }
    labels {
      key         = "product_id"
      description = "Filters by Product Id"
    }
    display_name = "Ordered Products Metric"
  }
  label_extractors = {
    # Regex extractor has matching group to match the product name or product id. Example: orderedItem="Terrarium", id="L9ECAV7KIM" 
    # matches Terrarium for product name and L9ECAV7KIM for product id.
    "product_name" = "REGEXP_EXTRACT(jsonPayload.message, \"orderedItem=\\\\\\\"([^\\\"]+)\\\\\\\"\")"
    "product_id"   = "REGEXP_EXTRACT(jsonPayload.message, \"id=\\\\\\\"([^\\\"]+)\\\\\\\"\")"
  }
}
