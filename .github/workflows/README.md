# GitHub Actions Workflows

workloads run using [GitHub self-hosted runners](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/about-self-hosted-runners)

## Setup

1. Create a GCE instance for running tests
    - VM should be at least n1-standard-4 with 50GB persistent disk
    - VM should be created with no service account
2. SSH into new VM through Google Cloud Console
3. Follow the instructions to add a new runner on the [Actions Settings page](https://github.com/GoogleCloudPlatform/stackdriver-sandbox/settings/actions) to authenticate the new runner
4. Set GitHub Actions as a background service
    - `sudo ~/actions-runner/svc.sh install ; sudo ~/actions-runner/svc.sh start`
5. Run the following command to install dependencies
    - `wget -O - https://raw.githubusercontent.com/GoogleCloudPlatform/stackdriver-sandbox/master/.github/workflows/install-dependencies.sh | bash`

---
## Workflows

### ci.yaml

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
- deploys manifests from /releases
  - ensures all pods reach ready state
  - ensures HTTP request to frontend returns HTTP status 200
