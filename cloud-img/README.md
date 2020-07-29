# Custom Image for Stackdriver Sandbox Project

When the Dockerfile changes, here are the steps to follow in order to push it to GCR:

Build the Dockerfile, tag the image, and push the image to the Container Registry.

```bash
$ docker build -t cloudshell-image .

$ gcloud auth configure-docker 

$ docker tag cloudshell-image gcr.io/stackdriver-sandbox-230822/cloudshell-image

$ docker push gcr.io/stackdriver-sandbox-230822/cloudshell-image

```

See the [Google documentation for Container Registry](cloud.google.com/container-registry/docs/quickstart)  for more information.
