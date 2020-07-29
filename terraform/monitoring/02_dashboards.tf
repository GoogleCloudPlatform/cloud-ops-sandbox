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
# of requests, distribution of types of requests, and response types. The JSON object
# containing the exact details of the dashboard can be found in the 'dashboards' folder.
resource "google_monitoring_dashboard" "userexp_dashboard" {
	dashboard_json = file("./dashboards/userexp_dashboard.json")
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

# This resource creates dashboards for the frontend service of the
# Stackdriver Sandbox. The JSON object containing the exact details
# of the dashboard can be found in the 'dashboards' folder.
resource "google_monitoring_dashboard" "frontend_dashboard" {
  dashboard_json = file("./dashboards/frontend_dashboard.json")
} 
