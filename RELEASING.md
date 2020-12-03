# Releasing

There are two artifacts that make up a Stackdriver Sandbox release:
- A set of tagged container images in "gcr.io/stackdriver-sandbox-230822/service_name"
- A set of manifests and code, saved as a git tag in this repository

Contributors can use `./make-release.sh`, along with
[GitHub Actions automation](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/tree/master/.github/workflows), 
to produce both at once.

## Release Process
1. run `export NEW_VERSION=vX.Y.Z`
   - see [Version Names](#version-names)
1. run `./make-release.sh`
   - tip: try running with `--dry-run` or `--no-push` first to do sanity checks
1. The script will open a new release branch on the origin repository. Create a pull request for the release
1. The script will push a git tag to the repo, which should kick off a
   [`push-tags` CI job](https://github.com/GoogleCloudPlatform/stackdriver-sandbox/blob/master/.github/workflows/push-tags.yml).
   Check that the job completed successfully, and the tagged images appear in the
   [`stackdriver-sandbox-230822` GCR repo](http://console.cloud.google.com/gcr/images/stackdriver-sandbox-230822)
1. When the PR has been reviewed and thoroughly tested, merge it into master
   - Don't squash; we must keep the tagged commit in the git history
1. The merge to master should kick off a
   [`github-pages` job](https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/deployments/activity_log?environment=github-pages)
   to re-build the website. Ensure that [cloud-ops-sandbox.dev](https://stackdriver-sandbox.dev/)
   was updated to use the new tag when you press the "Open in Cloud Shell" button
1. Do a manual sanity check, running through a deployment on [cloud-ops-sandbox.dev](https://cloud-ops-sandbox.dev/) to make sure everything still works

## Version Names
Version names should generally follow [semantic versioning](https://semver.org/) conventions:
- vX.Y.Z
  - X = major version: for major milestone or breaking changes
  - Y = minor version: for regularly scheduled milestone releases
  - Z =  Patch version: for hotfixes and other minor, unscheduled releases

## Reverting Faulty Releases
Once a release has been merged to master and finalized, **it is strongly advised not to delete or modify its artifacts**.
Instead, you should push a new patch to fix any issues that may have come up.

If a faulty release is still in the PR stage, or you have decided a deletion is necessary, here are the steps to do so:
1. Delete the tags from your local repository with `git tag -d $NEW_VERSION`
1. Delete the tags from origin with `git push --delete origin $NEW_VERSION`
1. Remove the `NEW_VERSION` tag from each image on the [`stackdriver-sandbox-230822` GCR repo](http://console.cloud.google.com/gcr/images/stackdriver-sandbox-230822)
1. Delete the release PR and branch from the GitHub web interface
