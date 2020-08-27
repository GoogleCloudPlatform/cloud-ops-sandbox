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

# Let's create the GKE cluster! This one's pretty complicated so buckle up.

# This is another example of the random provider. Here we're using it to pick a
# zone in us-central1 at random.
resource "random_shuffle" "zone" {
  input = ["us-central1-a", "us-central1-b", "us-central1-c", "us-central1-f"]

  # Seeding the RNG is technically optional but while building this we
  # found that it only ever picked `us-central-1c` unless we seeded it. Here
  # we're using the ID of the project as a seed because it is unique to the
  # project but will not change, thereby guaranteeing stability of the results.
  seed = data.google_project.project.project_id
}

# First we create the cluster. If you're wondering where all the sizing details
# are, they're below in the `google_container_node_pool` resource. We'll get
# back to that in a minute.
#
# One thing to note here is the name of the resource ("gke") is only used
# internally, for instance when you're referencing the resource (eg
# `google_container_cluster.gke.id`). The actual created resource won't know
# about it, and in fact you can specify the name for that in the resource
# itself.
#
# Finally, there are many, many other options available. The resource below
# replicates what the Hipster Shop README creates. If you want to see what else
# is possible, check out the docs: https://www.terraform.io/docs/providers/google/r/container_cluster.html
resource "google_container_cluster" "gke" {
  project = data.google_project.project.project_id

  # Here's how you specify the name
  name = "cloud-ops-sandbox"

  # Set the zone by grabbing the result of the random_shuffle above. It
  # returns a list so we have to pull the first element off. If you're looking
  # at this and thinking "huh terraform syntax looks a clunky" you are NOT WRONG
  location = element(random_shuffle.zone.result, 0)

  # Using an embedded resource to define the node pool. Another
  # option would be to create the node pool as a separate resource and link it
  # to this cluster. There are tradeoffs to each approach.
  #
  # The embedded resource is convenient but if you change it you have to tear
  # down the entire cluster and rebuild it. A separate resource could be
  # modified independent of the cluster without the cluster needing to be torn
  # down.
  #
  # For this particular case we're not going to be modifying the node pool once
  # it's deployed, so it makes sense to accept the tradeoff for the convenience
  # of having it inline.
  #
  # Many of the paramaters below are self-explanatory so I'll only call out
  # interesting things.
  node_pool {
    node_config {
      machine_type = "n1-standard-2"

      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"  
      ]

      labels = {
        environment = "dev",
        cluster = "cloud-ops-sandbox-main"   
      }
    }

    initial_node_count = 4

    autoscaling {
      min_node_count = 3
      max_node_count = 10
    }

    management {
      auto_repair  = true
      auto_upgrade = true
    }
  }

  # Specifies the use of "new" Cloud logging and monitoring
  # https://cloud.google.com/kubernetes-engine-monitoring/
  logging_service = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Stores the zone of created gke cluster
  provisioner "local-exec" {
    command = "gcloud config set compute/zone ${element(random_shuffle.zone.result, 0)}"
  }
  
  # add a hint that the service resource must be created (i.e., the service must
  # be enabled) before the cluster can be created. This will not address the
  # eventual consistency problems we have with the API but it will make sure
  # that we're at least trying to do things in the right order.
  depends_on = [google_project_service.gke]
}


# Set current project 
resource "null_resource" "current_project" {
  provisioner "local-exec" {
    command = "gcloud config set project ${data.google_project.project.project_id}"
  }
}

#resource "null_resource" "sleeping_subprocess" {
#  provisioner "local-exec" {
#      command = "sleep 60 >./stdout.log 2>./stderr.log & echo \"sleeping in PID\" $!"
#  }
#
#  depends_on = [google_container_cluster.gke]
#}

# Setting kubectl context to currently deployed GKE cluster
resource "null_resource" "set_gke_context" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials cloud-ops-sandbox --zone ${element(random_shuffle.zone.result, 0)} --project ${data.google_project.project.project_id}"
  }

  depends_on = [
    google_container_cluster.gke, 
    null_resource.current_project
  ]
}

# Install Istio into the GKE cluster
resource "null_resource" "install_istio" {
  provisioner "local-exec" {
    command = "./istio/install_istio.sh"
  }

  depends_on = [null_resource.set_gke_context]
}

# Deploy microservices into GKE cluster 
resource "null_resource" "deploy_services" {
  provisioner "local-exec" {
    command = "kubectl apply -f ../kubernetes-manifests"
  }

  depends_on = [null_resource.install_istio]
}

# We wait for all of our microservices to become available on kubernetes
resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = <<-EOT
    kubectl wait \-\-for=condition=available \-\-timeout=600s deployment/adservice
    kubectl wait \-\-for=condition=available \-\-timeout=600s deployment/cartservice
    kubectl wait \-\-for=condition=available \-\-timeout=600s deployment/checkoutservice
    kubectl wait \-\-for=condition=available \-\-timeout=600s deployment/currencyservice
    kubectl wait \-\-for=condition=available \-\-timeout=600s deployment/emailservice
    kubectl wait \-\-for=condition=available \-\-timeout=600s deployment/frontend
    kubectl wait \-\-for=condition=available \-\-timeout=600s deployment/paymentservice
    kubectl wait \-\-for=condition=available \-\-timeout=600s deployment/productcatalogservice
    kubectl wait \-\-for=condition=available \-\-timeout=600s deployment/recommendationservice
  EOT
  }

  triggers = {
    "before" = null_resource.deploy_services.id
  }
}

