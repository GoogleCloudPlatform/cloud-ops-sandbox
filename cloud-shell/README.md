# Custom Image for Stackdriver Sandbox Project

## Updating the Custom Image
The Stackdriver Sandbox website currently points at the image stored in Google Container Registry (GCR). If a project developer wants to change the Custom Image, it is **not enough** to update the Dockerfile stored in this directory. The developer must additionally update the image stored in GCR.

Steps to update the image locally and from GCP are described below.

### Steps for updating Dockerfile locally
1. After changing the Dockerfile locally, build the Dockerfile. 

```bash
$ docker build -t cloudshell-image .
```

1. Set up docker to authenticate using `gcloud` (only if developer has not previously done this). *Note: Currently only developers with 'Owner' permissions can push images to GCR.*

```bash
$ gcloud auth configure-docker 
```
1. Tag the image. This will enable docker to push it to the correct location (the project GCR registry), and automatically show this image as "latest" unless another tag is specified by adding `:my_tag` to the command below.
```bash
$ docker tag cloudshell-image gcr.io/stackdriver-sandbox-230822/cloudshell-image
```

1. Finally, push the image. It should be visible in the registry.
```bash
$ docker push gcr.io/stackdriver-sandbox-230822/cloudshell-image
```

See the [Google documentation for Container Registry](https://cloud.google.com/container-registry/docs/quickstart)  for more information on these steps.

### Steps for updating Dockerfile from GCP
1. If the Dockerfile is available in `stackdriver-sandbox` project, edit by running `cloudshell edit Dockerfile` once in the proper directory in Cloud Shell.

1. Build locally and test the image.
```bash
$ cloudshell env build-local # builds the image
$ cloudshell env run # starts the custom environment
$ exit
```
1. Push the image to GCR.
```bash
$ cloudshell env push
```

More information can be found on the steps above by running `teachme /google/devshell/tutorials/custom-image-tutorial.md` in GCP Cloud Shell.
