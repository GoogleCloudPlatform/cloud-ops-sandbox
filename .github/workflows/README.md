# GitHub Actions Workflows

workloads run using [GitHub self-hosted runners](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/about-self-hosted-runners)

## Setup

1. Create a GCE instance for running tests
    - VM should be at least n1-standard-4 with 100GB persistent disk
    - VM should be created with appropriate service account for desired [worker tag](#Tags)
2. SSH into new VM through Google Cloud Console
3. Follow the instructions to add a new runner on the [Actions Settings page](https://github.com/GoogleCloudPlatform/stackdriver-sandbox/settings/actions) to authenticate the new runner
4. Attach the [appropriate tag(s)](#Tags) to the new runner
5. Set GitHub Actions as a background service
    - `sudo ~/actions-runner/svc.sh install ; sudo ~/actions-runner/svc.sh start`
6. Run the following command to install dependencies
    - `wget -O - https://raw.githubusercontent.com/GoogleCloudPlatform/stackdriver-sandbox/master/.github/workflows/install-dependencies.sh | bash`

## Tags
- `kind-cluster`
  - default worker
  - needs no special privileges
    - should have no service account for security reasons
- `push-privilege`
  - image push worker
  - requires permissions to push images to GCR storage bucket, and deploy to App Engine
  - requires `PROJECT_ID` to be set properly in the [repo's secrets](https://github.com/GoogleCloudPlatform/stackdriver-sandbox/settings/secrets)
- `e2e-worker`
  - end to end test worker
  - requires the following permissions on the end-to-end test project:
    - `kubernetes engine admin`
    - `compute admin`
    - `monitoring admin`
    - `logging admin`
    - `storage admin` access to the GCR and terraform data buckets
  - requires `E2E_PROJECT_ID` to be set properly in the [repo's secrets](https://github.com/GoogleCloudPlatform/stackdriver-sandbox/settings/secrets)

---
## Workflows

### CI.yaml

#### Triggers

- commits pushed to master
- PRs to master
- PRs to release/ branches

#### Actions

- ensures kind cluster is running
- builds all containers in src/
- deploys local containers to kind
  - ensures all pods reach ready state
  - ensures HTTP request to frontend returns HTTP status 200


### Push-Master.yaml

#### Triggers
- commits pushed to master

#### Actions
- builds and pushes images to official GCR repo tagged with git commit
- builds and pushes images to official GCR repo tagged as latest


### Push-Tags.yaml

#### Triggers
- tags pushed to repo

#### Actions
- builds and pushes images to official GCR repo tagged with git tag name


### E2E.yaml

#### Triggers
- on each commit to master
- on each commit to a release branch
- on each PR into master

#### Actions
- ensure end-to-end test project has deleted all test resources
- build fresh containers for all services and the custom cloud shell image
- rewrite the kubernetes manifests to test with local images
- run install.sh script against end-to-end test project
- clean up resources in test project

