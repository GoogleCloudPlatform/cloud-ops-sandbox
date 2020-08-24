# Copyright 2020 Google LLC
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

# Creates a log-based metric by extracting a specific log written by the Checkout Service. 
# The log being used for the metric is from the Checkout Service and has the format:
# orderedItem="Vintage Typewriter", id="OLJCESPC7Z"
#
# The label and Regex extractor are used to create filters on the metric
# This resource creates only the metric
resource "google_logging_metric" "checkoutservice_logging_metric" {
  name   = "checkoutservice_log_metric"
  filter = "resource.type=k8s_container AND resource.labels.cluster_name=cloud-ops-sandbox AND resource.labels.namespace_name=default AND resource.labels.container_name=server AND orderedItem"
  metric_descriptor {
    metric_kind = "DELTA"  # set to DELTA for counter-based metric
    value_type  = "INT64"  # set to INT64 for counter-based metric
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

# Creates a dashboard and chart for the log-based metric defined above.
# Uses the label to group by the product name
resource "google_monitoring_dashboard" "log_based_metric_dashboard" {
  dashboard_json = <<EOF
{
  "displayName": "Log Based Metric Dashboard",
  "gridLayout": {
    "columns": "2",
    "widgets": [
      {
        "title": "Number of Products Ordered grouped by Product Name",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "metric.type=\"logging.googleapis.com/user/${google_logging_metric.checkoutservice_logging_metric.name}\" resource.type=\"k8s_container\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_RATE",
                    "crossSeriesReducer": "REDUCE_MEAN",
                    "groupByFields": [
                      "metric.label.\"product_name\""
                    ]
                  }
                }
              },
              "plotType": "LINE",
              "minAlignmentPeriod": "60s"
            }
          ],
          "yAxis": {
            "label": "y1Axis",
            "scale": "LINEAR"
          },
          "chartOptions": {
            "mode": "COLOR"
          }
        }
      }
    ]
  }
}
EOF
}
