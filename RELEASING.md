# Releasing

There are two artifacts that make up a Cloud Operations Sandbox release:
- A set of tagged container images in "gcr.io/stackdriver-sandbox-230822/service_name"
- A set of manifests and code, saved as a git tag in this repository

## Release Process
1. Navigate to the [make-release GitHub Action](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/actions/workflows/make-release.yml)i
1. Select the "Run workflow" dropdown, enter a new version number (`vX.Y.Z`), and target the `develop` branch
   - see [Version Names](#version-names)
1. The GitHub Action will run to kick off a new release PR. Verify that the expected artifacts were created:
  - a new PR from `develop` to `main`
  - the PR codebase should have the new version in:
    - the k8s manifests
    - README.md
    - cloud-shell/Dockerfile
    - website/layouts/index.html
    - website/deploy/index.html""
    - terraform/telemetry.py should be set to prod
  - a new git tag should have been pushed for the new release version
  - updated container images (hipstershop services, loadgenerator, cloud shell container) should be pushed in the [`stackdriver-sandbox-230822` GCR repo](http://console.cloud.google.com/gcr/images/stackdriver-sandbox-230822)
1. Review the new release pull request.
  - Hint: use `sandboxctl test` to run tests on a live, newly-created sandbox environment
  - If any issues arise, delete the branch and tag, push new changes to develop, and start the release process again (see [Reverting Faulty Releases](#reverting-faulty-releases))
1. When the PR has been reviewed and thoroughly tested, merge it into main
   - Don't squash; we want to keep the git history
1. Manually promote the tag to a release on the [GitHub Releases page](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/releases)
1. The merge to main should kick off a [CI job](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/actions/workflows/update-website.yml)
    to re-build the website. Ensure that [cloud-ops-sandbox.dev](https://cloud-ops-sandbox.dev/)
    was updated to use the new tag when you press the "Open in Cloud Shell" button
1. Do a manual sanity check, running through a deployment on [cloud-ops-sandbox.dev](https://cloud-ops-sandbox.dev/) to make sure everything still works

## Version Names
Version names should generally follow [semantic versioning](https://semver.org/) conventions:
- vX.Y.Z
  - X = major version: for major milestone or breaking changes
  - Y = minor version: for regularly scheduled milestone releases
  - Z =  Patch version: for hotfixes and other minor, unscheduled releases

## Reverting Faulty Releases
Once a release has been merged to main and finalized, **it is strongly advised not to delete or modify its artifacts**.
Instead, you should push a new patch to fix any issues that may have come up.

If a faulty release is still in the PR stage, or you have decided a deletion is necessary, here are the steps to do so:
1. Delete the tags from your local repository with `git tag -d $NEW_VERSION`
1. Delete the tags from origin with `git push --delete origin $NEW_VERSION`
1. Remove the `NEW_VERSION` tag from each image on the [`stackdriver-sandbox-230822` GCR repo](http://console.cloud.google.com/gcr/images/stackdriver-sandbox-230822)
1. Delete the release PR and branch from the GitHub web interface
