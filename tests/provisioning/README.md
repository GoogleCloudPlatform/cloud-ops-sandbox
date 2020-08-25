# Tests for Cloud Ops Sandbox Provisioning

This test is integrated into the Github CI system. If you want to run it manually, please follow the steps below and *make sure you are running on the Cloud Shell*.

1. Build docker
```bash
docker build -t $image_name .
```

2. Run docker
```bash
docker run --rm -e GOOGLE_CLOUD_PROJECT=$project_id -e ZONE=$gke_zone $image_name
```
