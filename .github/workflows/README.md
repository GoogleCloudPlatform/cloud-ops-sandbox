# GitHub Action Workflows

This page describes Github workflows that are triggered by various events in the repo.
All workflows use Github actions v3.

## Workflow Backend

All workflows are configured to use [Github-hosted][hosted] runners.
The goal is to perform maximum operations at managed tier and to use self-hosting for integration tests.
Google Cloud project parameters are defiend as the repo's secrets.
The backend of the end-to-end tests is hosted on Google Cloud.
Authentication uses keyless approach.
Permission sets are optimized to avoid accidental sandbox breaches and permission elevations.

## Workflows

> **Note**: Some checks (including enforced by Github branch protection policies) are executed by [bots].

All workflows run on `ubuntu:latest` runners.
Unless explicitly defined, all workflows are triggered:

```yaml
on:
  pull_request:
    types: [opened,synchronize,reopened]
```

In order to minimize the number of runners, each job is compartmentized per workflow and branch:

```yaml
jobs:
  some_job:
    concurrency:
      group: ${{ github.workflow }}-${{ github.ref }}
      cancel-in-progress: true
```

### Terraform Lint - [lint-terraform.yaml]

The workflow is triggered by changes to Terraform configurations used for provisioning Cloud Ops Sandbox:

```yaml
on:
  pull_request:
    paths:
      - 'provisioning/terraform/**'
```

It uses the [tflint] Github action.
To support required checks, the file contains "extra" workflow that _does nothing_ when triggered for changes outside the Terraform configuration.

### End-to-end Deployment

The workflow is triggered by pull request modifications (excluding a closure of the request) for branches `main` and branches with names starting with `milestone/` or `release/`.
The workflow is not triggered for changes to documentation or markdown files.
Permissions are updated to acquire the identity token from Google Cloud Identity service. See [blog] for more details.

The workflow installs Google Cloud CLI to complete the list of required binaries (gcloud, git, kubectl).
Then it triggers installation of Cloud Ops Sandbox using [install.sh] script.
The deployment reuses the same GCS bucket to maintain Terraform state for all workflow executions but prefixes each one with the first 7 digits of SHA ( [`${{ github.sha }}`][sha] )of the commit.
The installation is triggered with the following parameters:

* Customized Terraform state prefix (`"${SHA:0:7}`)
* Custom cluster name (`"${SHA:0:7}-cloudops-sandbox"`)
* Allowing deployment of the load generator
* Disabling configuration of Anthos Service Mesh and deployment of Online Boutique ingress

[hosted]: https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners
[bots]: ../README.md
[lint-terraform.yaml]: ./lint-terraform.yaml
[tflint]: https://github.com/marketplace/actions/setup-tflint
[blog]: https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions
[install.sh]: ../../provisioning/install.sh
[sha]: https://docs.github.com/en/actions/learn-github-actions/contexts#github-context
