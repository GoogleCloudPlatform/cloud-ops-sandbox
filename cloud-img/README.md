# Custom Image for Stackdriver Sandbox Project

When the Dockerfile changes, here are the steps to follow in order to push it to GCR:

Build the Dockerfile, tag the image, and push the image to the Container Registry.

```bash
$ docker build sandbox-img

$ docker tag sandbox-img gcr.io/stackdriver-sandbox-230822/sandbox-img:tag1

$ docker push gcr.io/stackdriver-sandbox-230822/sandbox-img:tag1
```
