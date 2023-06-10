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

### Terraform workflow ([terraform.yaml])

The workflow is triggered by changes to Terraform configurations in the project:

```yaml
on:
  pull_request:
    paths:
      - 'provisioning/terraform/**'
```

It defines two jobs:

1. Linting that validates formatting and other rules and dependecies using [tflint]
2. End-to-end deployment that provisions Online Boutique demo app with Sandbox from scratch.
And destroys it afterward.

#### End-to-end deployment steps

Then it triggers installation of Cloud Ops Sandbox using [install.sh] script.
The deployment reuses the same GCS bucket to maintain Terraform state for all workflow executions but prefixes each one with the first 7 digits of SHA ( [`${{ github.sha }}`][sha] )of the commit.
The installation is triggered with the following parameters:

* Customized Terraform state prefix (`"${SHA:0:7}`)
* Custom cluster name (`"${SHA:0:7}-cloudops-sandbox"`)
* Allowing deployment of the load generator
* Disabling configuration of Anthos Service Mesh and deployment of Online Boutique ingress

#### Handling skipped but required checks

The additional file [non-terraform.yaml] defines the workflow with the same name to support
the use of the workflow as [required status check].
It is configured to run on any "non-terraform" changes, so the required workflow will always
guaranteed to terminate.

### Configurations workflow ([configurations.yaml])

The `configurations` checks correctness of the Sandbox configurations. It includes:

* yaml linting
* validation of the configuration's yaml files vs. schema that is defined following JSON schema [draft2020]
* json linting
* testing configuration vs. expected terraform plan to make sure that all components are built using "right" provider and resource definitions

### Required workflows

The workflows triggered by pull request modifications (excluding a closure of the request)
are enforced on `main` and branches with names starting with `milestone/` or `release/`.

### Running jobs that require Google Cloud authentication

Jobs that need to authenticate vs. Google Cloud use keyless authentication method.
The method is described with more details in the [blog].
Job permissions are updated to allow storing id token.
The workflow installs Google Cloud CLI to complete the list of required binaries (gcloud, git, kubectl).

## GitHub configurations and bots

The repo defines templates for new [pull requests], [bugs] and [features].
The configurations include the following bots:

* [Blunderbuss]: Auto-assigner of a Github users to pull requests and issues
* [Header checker]: Presubmit check that all files with configured extensions have the proper copyright header
* [Conventional commit lint]: Presubmit check that all commit messages in PR follow the [convention]
* [Snippets]: Scanner for possible code sample snippets to integrate them into Google Cloud documentation
* [Trusted contributors]: Integrator for Github application trusted access to the repo

For information about the customized workflow, see [workfows/README]

[hosted]: https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners
[bots]: ../README.md
[terraform.yaml]: ./terraform.yaml
[non-terraform.yaml]: ./non-terraform.yaml
[tflint]: https://github.com/marketplace/actions/setup-tflint
[blog]: https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions
[install.sh]: ../../provisioning/install.sh
[sha]: https://docs.github.com/en/actions/learn-github-actions/contexts#github-context
[required status check]: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches#require-status-checks-before-merging
[pull requests]: ./PULL_REQUEST_TEMPLATE.md
[bugs]: ISSUE_TEMPLATE/bug_report.md
[features]: ISSUE_TEMPLATE/feature_request.md
[blunderbuss]: https://github.com/googleapis/repo-automation-bots/tree/main/packages/blunderbuss
[header checker]: https://github.com/googleapis/repo-automation-bots/tree/main/packages/header-checker-lint
[workfows/README]: workflows/README.md
[conventional commit lint]: https://github.com/googleapis/repo-automation-bots/tree/main/packages/conventional-commit-lint
[convention]: https://www.conventionalcommits.org/en/v1.0.0/
[snippets]: https://github.com/googleapis/repo-automation-bots/tree/main/packages/snippet-bot
[trusted contributors]: https://github.com/googleapis/repo-automation-bots/tree/main/packages/trusted-contribution
[draft2020]: https://json-schema.org/draft/2020-12/release-notes.html
