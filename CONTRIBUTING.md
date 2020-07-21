# How to Contribute

We'd love to accept your patches and contributions to this project. There are
just a few small guidelines you need to follow. In the last section [Build Sandbox Locally](#build-sandbox-locally), we will show you how to build the project locally.

## Development Principles (for Googlers)

There are a few principles for developing or refactoring the service
implementations. Read the [Development Principles
Guide](./docs/development-principles.md).

## Contributor License Agreement

Contributions to this project must be accompanied by a Contributor License
Agreement. You (or your employer) retain the copyright to your contribution;
this simply gives us permission to use and redistribute your contributions as
part of the project. Head over to <https://cla.developers.google.com/> to see
your current agreements on file or to sign a new one.

You generally only need to submit a CLA once, so if you've already submitted one
(even if it was for a different project), you probably don't need to do it
again.

## Code reviews

All submissions, including submissions by project members, require review. We
use GitHub pull requests for this purpose. Consult
[GitHub Help](https://help.github.com/articles/about-pull-requests/) for more
information on using pull requests.

## Community Guidelines

This project follows [Google's Open Source Community
Guidelines](https://opensource.google.com/conduct/).

## Build Sandbox Locally

> **Note:** The first build can take up to 30 minutes. Subsequent builds
> will be faster.

### Option 1: Running locally with “Docker for Desktop”

> 💡 Recommended if you're planning to develop the application.

1. Install tools to run a Kubernetes cluster locally:

   * kubectl (can be installed via `gcloud components install kubectl`)
   * Docker for Desktop (Mac/Windows): It provides Kubernetes support as [noted
     here](https://docs.docker.com/docker-for-mac/kubernetes/).
   * [skaffold](https://github.com/GoogleContainerTools/skaffold/#installation)
     (ensure version ≥v0.20)

1. Launch “Docker for Desktop”. Go to **Preferences**:
   * Choose **Enable Kubernetes**
   * Set **CPUs** to at least 3
   * Set **Memory** to at least 6.0 GiB

1. Run `kubectl get nodes` to verify you're connected to “Kubernetes on Docker”.

1. Run `skaffold run` (first time will be slow; it can take up to 30 minutes).
   This will build and deploy the application. If you need to rebuild the images
   automatically as you refactor he code, run the `skaffold dev` command.

1. Run `kubectl get pods` to verify the Pods are ready and running. The
   application frontend should be available at <http://localhost:80> on your
   machine.

### Option 2: Running on Google Kubernetes Engine (GKE)

> 💡  Recommended for demos and making it available publicly.
> ℹ️   This task can be automated with `make cluster PROJECT_ID=my-project`

1. Install tools specified in the previous section (Docker, kubectl, skaffold)

1. Create a Google Kubernetes Engine cluster and make sure `kubectl` is pointing
   to the cluster:

```bash
gcloud services enable container.googleapis.com

gcloud container clusters create demo --zone=us-central1-a \
    --machine-type=n1-standard-2 \
    --num-nodes=4 \
    --enable-stackdriver-kubernetes \
    --scopes https://www.googleapis.com/auth/cloud-platform

kubectl get nodes
```

1. Enable Google Container Registry (GCR) on your GCP project and configure the
   `docker` CLI to authenticate to GCR:

```bash
gcloud services enable containerregistry.googleapis.com

gcloud auth configure-docker -q
```

1. In the root of this repository, run `skaffold run --default-repo=gcr.io/[PROJECT_ID]`,
   where [PROJECT_ID] is the identifier for your GCP project.

   This command:
   * Builds the container images.
   * Pushes them to GCR.
   * Applies the `./kubernetes-manifests` deploying the application to
     Kubernetes.

   **Troubleshooting:** If you get the error "No space left on device" on Google
   Cloud Shell, you can build the images on Google Cloud Build. To do this:
   1. [Enable the Cloud Build
       API](https://console.cloud.google.com/flows/enableapi?apiid=cloudbuild.googleapis.com).

   2. Run `skaffold run -p gcb  --default-repo=gcr.io/[PROJECT_ID]`.

1. Find the IP address of your application, then visit the application on your
    browser to confirm installation.

```bash
kubectl get service frontend-external
```

1. To create monitoring examples in GCP, navigate to the monitoring folder and run 
the `terraform apply` command.

   2. Please note that in order to do this you will need the external IP address, project ID, 
   and an email address. The project ID can be found in GCP or with the command `gcloud config get-value project`

```bash
cd ./monitoring

terraform apply
```
> **Troubleshooting:** A Kubernetes bug (will be fixed in 1.12) combined with
> a Skaffold [bug](https://github.com/GoogleContainerTools/skaffold/issues/887)
> causes the load balancer to not work, even after getting an IP address. If you
> are seeing this, run `kubectl get service frontend-external -o=yaml | kubectl apply -f-`
> to trigger load-balancer reconfiguration.

### Option 3: Using Static Images

> 💡 Recommended for test-driving the application on an existing cluster.

**Prerequisite**: a running Kubernetes cluster.

1. Clone this repository.
1. Deploy the application: `kubectl apply -f ./release/kubernetes-manifests`  
1. Run `kubectl get pods` to see pods are in a healthy and ready state.
1. Find the IP address of your application, then visit the application on your
    browser to confirm installation.

```bash
kubectl get service frontend-external
```

### Generate Synthetic Traffic

1. If you want to create synthetic load manually, use the `loadgen` executable found in the loadgenerator folder of the repository. For example:

```bash
./loadgenerator/loadgen startup --zone us-central1-c [SANDBOX_FRONTEND_ADDRESS]
```

### (Optional) Using the Makefile

The project contains an optional makefile to automate several common development tasks

1. Creating a cluster

```bash
make cluster PROJECT_ID=my-project
```

2. Building and deploying from source

  - a) Standard (single deploy)
```bash
make deploy PROJECT_ID=my-project
```

  - b) Continuously (re-deploy on each file change)
```bash
make deploy-continuous PROJECT_ID=my-project
```

3. Viewing logs

```bash
make logs SERVICE=x
```

### (Optional) Deploying on a Istio-installed GKE cluster

> **Note:** If you followed GKE deployment steps above, run `skaffold delete` first
> to delete what's deployed.

1. Create a GKE cluster (described above).

1. Use [Istio on GKE add-on](https://cloud.google.com/istio/docs/istio-on-gke/installing)
   to install Istio to your existing GKE cluster.

```bash
gcloud beta container clusters update demo \
    --zone=us-central1-a \
    --update-addons=Istio=ENABLED \
    --istio-config=auth=MTLS_PERMISSIVE
```

> NOTE: If you need to enable `MTLS_STRICT` mode, you will need to update
> several manifest files:
>
> * `kubernetes-manifests/frontend.yaml`: delete "livenessProbe" and
>   "readinessProbe" fields.
> * `kubernetes-manifests/loadgenerator.yaml`: delete "initContainers" field.

1. (Optional) Enable Stackdriver Tracing/Logging with Istio Stackdriver Adapter
   by following [this guide](https://cloud.google.com/istio/docs/istio-on-gke/installing#enabling_tracing_and_logging).

1. Install the automatic sidecar injection (annotate the `default` namespace
   with the label):

```bash
kubectl label namespace default istio-injection=enabled
```

1. Apply the manifests in [`./istio-manifests`](./istio-manifests) directory.

```bash
kubectl apply -f ./istio-manifests
```

This is required only once.

1. Deploy the application with `skaffold run --default-repo=gcr.io/[PROJECT_ID]`.

1. Run `kubectl get pods` to see pods are in a healthy and ready state.

1. Find the IP address of your Istio gateway Ingress or Service, and visit the
   application.

```bash
INGRESS_HOST="$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "$INGRESS_HOST"
curl -v "http://$INGRESS_HOST"
```

### (Optional) Building and Running Individual Services Locally

> 💡 Recommended for quick, repeatable debugging an individual microservice.

Each service runs in its own docker container; you can view the container images pushed to your GCP project's [Container Registry](https://console.cloud.google.com/gcr/images/). Instead of using something like GCP Cloud Build, you can also build and run each container locally.

#### Authentication
This is required only once.

1. Configure docker to authenticate requests to your Container Registry.
```bash
gcloud auth configure-docker
```
2. [Create a service account](https://cloud.google.com/docs/authentication/getting-started#creating_a_service_account) and generate a key file, either through your GCP Console or through command line:

```bash
gcloud iam service-accounts create [NAME]
gcloud projects add-iam-policy-binding [PROJECT_ID] --member "serviceAccount:[NAME]@[PROJECT_ID].iam.gserviceaccount.com" --role "roles/owner"
gcloud iam service-accounts keys create [FILE_NAME].json --iam-account [NAME]@[PROJECT_ID].iam.gserviceaccount.com
```
Where `[NAME]` is the name you choose for your service account, `[PROJECT_ID]` is the name of your GCP project, and `[FILE_NAME]` is the path to + name of the file in which you wish to store your keys.

3. Set your `GOOGLE_APPLICATION_CREDENTIALS` environment variable on your machine.

Linux/macOS:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="[PATH]"
```
Windows:
```bash
$env:GOOGLE_APPLICATION_CREDENTIALS="[PATH]"
```

#### Docker Build and Run

1. Build and tag the image. Make sure you are in the service's directory (i.e. where the Dockerfile is) or pass in the relative path.
```bash
docker build . --tag gcr.io/[PROJECT_ID]/[IMAGE]
```

2. Run with the following flags (`-e` sets environment variables in the container and `-v` injects the credential file).

```bash
PORT=8080 && docker run \
-p 9090:${PORT} \
-e PORT=${PORT} \
-e K_SERVICE=dev \
-e K_CONFIGURATION=dev \
-e K_REVISION=dev-00001 \
-e GOOGLE_APPLICATION_CREDENTIALS=[FILE_NAME] \
-v $GOOGLE_APPLICATION_CREDENTIALS:[FILE_NAME] \
gcr.io/[PROJECT_ID]/[IMAGE]
```