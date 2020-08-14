# Copyright 2019 Google LLC
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

# Here we are creating a project to contain the deployed resources. A couple of
# general terraform notes: this is the first time we're seeing the `data`
# stanza. This gives a way to look stuff up and use it in other resources. Here
# we're looking up the billing account by name (hence why the README has you
# name it a certain way) so we can pass its ID on later.
#
# If productized we'd drop this and use the default billing account instead.
data "google_billing_account" "acct" {
  display_name = var.billing_account
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_project_service" "iam" {
  project = data.google_project.project.id

  service = "iam.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "compute" {
  project = data.google_project.project.id

  service = "compute.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "clouddebugger" {
  project = data.google_project.project.id

  service = "clouddebugger.googleapis.com"

  disable_dependent_services = true
}


resource "google_project_service" "cloudtrace" {
  project = data.google_project.project.id

  service = "cloudtrace.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "errorreporting" {
  project = data.google_project.project.id

  service = "clouderrorreporting.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "sourcerepo" {
  project = data.google_project.project.id

  service = "sourcerepo.googleapis.com"

  disable_dependent_services = true
}

# Enable GKE in the project we created. If you look at the docs you might see
# the `google_project_services` resource which allows you to specify a list of
# resources to enable. This seems like a good idea but there's a gotcha: to use
# that resource you have to specify a comprehensive list of services to be
# enabled for your project. Otherwise it will disable services you might be
# using elsewhere.
#
# For that reason, we use the single service option instead since it allows us
# granular control.
resource "google_project_service" "gke" {
  # This could just as easily reference `random_id.project.dec` but generally
  # you want to dereference the actual object you're trying to interact with.
  #
  # You'll see this line in every resource we create from here on out. This is
  # necessary because we didn't configure the provider with a project because
  # the project didn't exist yet. This could be refactored such that the project
  # was created outside of terraform, the provider configured with the project,
  # and then we don't have to specify this on every resource any more.
  #
  # Anyway, expect to see a lot more of these. I won't explain every time.
  project = data.google_project.project.id

  # the service URI we want to enable
  service = "container.googleapis.com"

  disable_dependent_services = true
}
