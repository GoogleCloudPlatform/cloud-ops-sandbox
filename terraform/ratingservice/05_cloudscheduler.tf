/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_cloud_scheduler_job" "recollect_job" {
  project = data.google_project.project.project_id
  name             = "ratingservice-recollect-job"
  schedule         = "* * * * *" # each minute
  description      = "recollect recently posted new votes"
  time_zone        = "Europe/London"
  region           = var.gcp_region_name
  attempt_deadline = "340s"

  retry_config {
    min_backoff_duration = "1s"
    max_retry_duration   = "10s"
    max_doublings        = 2
    retry_count          = 3
  }

  app_engine_http_target {
    http_method = "POST"

    app_engine_routing {
      service = var.service_name
      version = var.service_version
    }

    relative_uri = "/ratings:recollect"
  }

  depends_on = [google_project_service.cloudscheduler, google_app_engine_standard_app_version.ratingservice]
}
