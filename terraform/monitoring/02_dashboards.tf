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

# Here we create a dashboard for the general user experience - it contains metrics
# that reflect how users are interacting with the demo application such as latency
# of requests, distribution of types of requests, and response types.
resource "google_monitoring_dashboard" "userexp_dashboard" {
	dashboard_json = <<EOF
	{
  "displayName": "User Experience Dashboard",
  "gridLayout": {
    "columns": "2",
    "widgets": [
      {
        "title": "HTTP Request Count by Method",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "metric.type=\"custom.googleapis.com/opencensus/opencensus.io/http/server/request_count_by_method\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_RATE"
                  },
                  "secondaryAggregation": {}
                },
                "unitOverride": "1"
              },
              "plotType": "LINE",
              "minAlignmentPeriod": "60s"
            }
          ],
          "timeshiftDuration": "0s",
          "yAxis": {
            "label": "y1Axis",
            "scale": "LINEAR"
          },
          "chartOptions": {
            "mode": "COLOR"
          }
        }
      },
      {
        "title": "HTTP Response Errors",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "metric.type=\"custom.googleapis.com/opencensus/opencensus.io/http/server/response_count_by_status_code\" metric.label.\"http_status\"!=\"200\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_RATE"
                  },
                  "secondaryAggregation": {}
                },
                "unitOverride": "1"
              },
              "plotType": "LINE",
              "minAlignmentPeriod": "60s"
            }
          ],
          "timeshiftDuration": "0s",
          "yAxis": {
            "label": "y1Axis",
            "scale": "LINEAR"
          },
          "chartOptions": {
            "mode": "COLOR"
          }
        }
      },
      {
        "title": "HTTP Request Latency",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "metric.type=\"custom.googleapis.com/opencensus/opencensus.io/http/server/latency\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_DELTA",
                    "crossSeriesReducer": "REDUCE_PERCENTILE_99"
                  },
                  "secondaryAggregation": {}
                },
                "unitOverride": "ms"
              },
              "plotType": "LINE",
              "minAlignmentPeriod": "60s"
            }
          ],
          "timeshiftDuration": "0s",
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

# Here we create a dashboard for the adservice. The details of the charts
# in the dashboard can be found in the JSON specification file.
resource "google_monitoring_dashboard" "adservice_dashboard" {
  dashboard_json = file("./dashboards/adservice_dashboard.json")
}

# Here we create a dashboard for the recommendationservice. The details of the charts
# in the dashboard can be found in the JSON specification file.
resource "google_monitoring_dashboard" "recommendationservice_dashboard" {
  dashboard_json = file("./dashboards/recommendationservice_dashboard.json")
}
