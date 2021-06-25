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

### Option 1: Running locally

> 💡 Recommended if you're planning to develop the application.  
> ℹ️  Prerequisite: [Cloud SDK should be installed.](https://cloud.google.com/sdk/docs/quickstart)  
> ℹ️  Prerequisite: (if using macbook) Run the following:

```bash  
brew install coreutils
```

#### ![kubernetes](docs/img/kubernetes.png) Run Kubernetes micro-services with “Docker for Desktop”

1. Install tools to run a Kubernetes cluster locally:

   * kubectl (can be installed via `gcloud components install kubectl`)
   * [Docker for Desktop (Mac/Windows)](https://docs.docker.com/desktop/#download-and-install), It provides Kubernetes support as [noted
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

#### ![app engine](docs/img/app-engine.png) Run App Engine (rating) micro-service

> ℹ️   This task requires a running PostgreSQL DB instance with the configured rating database schema.

1. Follow the [Testing and deploying](https://cloud.google.com/appengine/docs/standard/python3/testing-and-deploying-your-app).
   * Install Python 3 (for example [download binaries](https://www.python.org/downloads/))
   * Install the service dependencies (via `pip3 -r requirements.txt`)
   * Define the required environment variables: `DB_HOST` -- PostgreSQL DB hostname; `DB_NAME` -- the name of the database where ratings are stored (usually "rating-db"); `DB_USERNAME` and `DB_PASSWORD` -- connecting credentials
   * Run the service (via `python3 main.py`)
   **NOTE:** If you run PostgreSQL DB locally you can reference [configure_rating_db.sh](terraform/ratingservice/configure_rating_db.sh) for the schema MDL

1. Configure frontend service to use the rating service endpoint.
   * Run `kubectl set env deployment/frontend RATING_SERVICE_ADDR=http://[host]:8080` where `[host]` is TBD
   * Restart frontend service pods: `kubectl rollout restart deployment/frontend`

1. When required to refresh the ratings according to recent votes send HTTP POST request to `http://[host]:8080/ratings:recollect`.

### Option 2: Running on GCP

> 💡  Recommended for demos and making it available publicly.

#### ![kubernetes](docs/img/kubernetes.png) Run Kubernetes micro-services on Google Kubernetes Engine (GKE)

> ℹ️   This task can be automated with `make cluster PROJECT_ID=my-project`

1. Install tools specified in the previous section (Docker, kubectl, skaffold)

1. Create a Google Kubernetes Engine cluster and make sure `kubectl` is pointing
   to the cluster:

```bash
gcloud services enable container.googleapis.com

gcloud container clusters create demo --zone=us-central1-a \
    --machine-type=n1-standard-2 \
    --num-nodes=2 \
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

1. Find the IP address of your Istio gateway Ingress or Service, and visit the
   application.

```bash
INGRESS_HOST="$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "$INGRESS_HOST"
curl -v "http://$INGRESS_HOST"
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

#### ![app engine](docs/img/app-engine.png) Run App Engine micro-service on Google App Engine (GAE)

> ℹ️   This task requires a running PostgreSQL DB instance with the configured rating database schema.
> ℹ️   This task requires having App Engine application created in the project.

1. Create `app.yaml` file in the `src/ratingservice` folder with the following content:

```yaml
runtime: python38
env: standard
service: ratingservice
version: prod
entrypoint: uwsgi --http-socket :8080 --wsgi-file main.py --callable app --master --processes 1 --threads 10
env_variables:
    DB_HOST: '[Place database hostname or IP]'
    DB_NAME: '[Place database name]'
    DB_USERNAME: '[Place username credential]'
    DB_PASSWORD: '[Place password credential]'
    MAX_DB_CONNECTIONS: 10
basic_scaling:
  max_instances: 10
  idle_timeout: 10m
```

1. Deploy rating service: `gcloud app deploy --project [PROJECT_ID]`. You have to run the command from the `src/ratingservice` folder.

1. Configure frontend service to use the rating service endpoint:

```bash
AE_DOMAIN=$(gcloud app describe --project=$project_id --format="value(defaultHostname)" 2>/dev/null)
kubectl set env deployment/frontend RATING_SERVICE_ADDR=https://ratingservice-dot-$AE_DOMAIN
kubectl rollout restart deployment/frontend
```

1. When required to refresh the ratings according to recent votes run:

```bash
AE_DOMAIN=$(gcloud app describe --project=$project_id --format="value(defaultHostname)" 2>/dev/null)
curl -X POST 'https://ratingservice-dot-$AE_DOMAIN/ratings:recollect'
```

### Option 3: Using Static Images

> 💡 Recommended for test-driving the application on an existing cluster.

**Prerequisite**: a running Kubernetes cluster.

1. Clone this repository.
1. Deploy the application: `kubectl apply -f ./release/kubernetes-manifests`  
1. Run `kubectl get pods` to see pods are in a healthy and ready state.
1. Find the IP address of your Istio gateway Ingress or Service, and visit the
   application.

```bash
INGRESS_HOST="$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "$INGRESS_HOST"
curl -v "http://$INGRESS_HOST"
```

**NOTE:** To run App Engine micro-service use the instructions from Option 2.

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

2. Building and deploying Kubernetes micro-services from source

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

### (Optional) Building and Running Individual Services Locally

> 💡 Recommended for quick, repeatable debugging an individual Kubernetes microservice.

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

## Open in Cloud Shell Links

When developing sandbox, it can be useful to launch a new Cloud Shell session straight from your branch. You can do this by modifying
and opening the following url:

https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/cloud-ops-sandbox.git&cloudshell_git_branch=**your-branch-here**&shellonly=true&cloudshell_image=gcr.io/stackdriver-sandbox-230822/cloudshell-image/uncertified:latest

When you're ready to open a PR, a GitHub Actions bot will attach an Open in Cloud Shell button directing to your changes automatically
