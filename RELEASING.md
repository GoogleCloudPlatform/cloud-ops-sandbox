# Releasing
Versioned releases of this repository can be built and published using `cloudbuild-release.yaml`.

When triggered, this Cloud Build config file will build all the microservices that make up the application and tag them with:
- the git tag that triggered the release
- the git hash associated with the tag
- with the 'latest' tag

Images will be pushed to Google Container Registry at the path "gcr.io/$PROJECT_ID/$REPO_NAME/service_name"

### Setting up the Release Trigger

1. Enable the [Cloud Build API](https://console.cloud.google.com/cloud-build/triggers) for your project
2. Select "Create a Trigger"
3. Enter the repository URL to link the trigger to your copy of this repository
4. Set the Trigger type as "Tag"
5. Set "Build Configuration" to "Cloud Build configuration file", and set the file location to `/cloudbuild-release.yaml`
6. Select the "Create trigger" button to finalize the trigger

### Adding a Release Version
1. run `git tag -a $YOUR_VERSION_NAME`
2. run `git push origin $YOUR_VERSION_NAME`
3. watch the trigger build and push new container images in [Google Cloud Build](https://console.cloud.google.com/cloud-build/builds).
