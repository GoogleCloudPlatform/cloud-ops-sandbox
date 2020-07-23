# Releasing

There are two artifacts that make up a Stackdriver Sandbox release:
- A set of tagged container images in "gcr.io/stackdriver-sandbox-230822/service_name"
- A set of manifests and code, saved as a git tag in this repository

Contributors can use `./make-release.sh`, along with
[GitHub Actions automation](https://github.com/GoogleCloudPlatform/stackdriver-sandbox/tree/master/.github/workflows), 
to produce both at once.

## Release Process
1. run `export NEW_VERSION=vX.Y.Z`
   - see [Version Names](#version-names)
1. run `./make-release.sh`
   - tip: try running with `--dry-run` or `--no-push` first
1. The script will open a new release branch on the origin repository. Create a pull request for the release
1. The script will push a git tag to the repo, which should kick off a [`push-tags` CI job](https://github.com/GoogleCloudPlatform/stackdriver-sandbox/blob/master/.github/workflows/push-tags.yml).
   Check that the job completed successfully, and the tagged images appear in the `stackdriver-sandbox-230822` GCR repo
1. When the PR has been reviewed and throughly tested, merge it into master
   - Don't squash; we must keep the tagged commit in the git history
1. The merge to master should kick off a [`github-pages` job](https://github.com/GoogleCloudPlatform/stackdriver-sandbox/deployments/activity_log?environment=github-pages) 
   to re-build the website. Ensure that [stackdriver-sandbox.dev](https://stackdriver-sandbox.dev/) was updated to use the new tag
1. Do a manual sanity check, running through a deployment on  [stackdriver-sandbox.dev](https://stackdriver-sandbox.dev/) to make sure everything still works

## Version Names
Version names should generally follow [semantic versioning](https://semver.org/) conventions:
- vX.Y.Z
  - X = major version: for major milestone or breaking changes
  - Y = minor version: for regularly scheduled milestone releases
  - Z=  Patch version: for hotfixes and other minor, unscheduled releases
