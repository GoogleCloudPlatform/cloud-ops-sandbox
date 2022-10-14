# GitHub applications and workflows

The repo uses the following Github applications:

* [Blunderbuss][blunderbuss]: a bot that assigns a randomly chosen user from
  [GoogleCloudPlatform/dee-observability][dee-obs-team] team.
* [Auto-label][auto-label]: a bot that assigns PR size and language labels
  based on the configuration.
* [Header checker][hdr-chk-lint]: runs checks that ensure existence of the
  proper copyright header with Google LLC license in all files (except
  markdown).

The repo's workflows include "Continuous Integration" and "End to end testing".
They are implemented differently due to existing authentication constraints.

## Continuous Integration workflow

The workflow is described in `.github\workflow\ci.yaml` file.
It runs a single job "Main CI pipeline" hosted on `ubuntu-latest`
[GitHub-hosted runner][github-runners].
It executes all "local" steps including linting, building and testing.

## End to end testing workflow

The end to end (e2e) testing workflow is implemented using
[Google Cloud Build application][gcb-app]. The Cloud Build trigger
"cloudops-sandbox-e2e-testing" runs Cloud Build configuration stored in the
`.github/cloudbuild.yaml` that provisions Sandbox artifacts for the test app
configuration. The workflow is configured to run multiple test instances in
parallel in the same Google Cloud project.

This implementation will be changed after enabling
[keyless authentication][no-key] vs. the Google Cloud project.

## Additional configurations

No configuration in the repo required to run these applications and workflows.
The Cloud Build trigger is configured with _STATE_BUCKET_NAME substituting
variable that defines the name of the storage bucket that is used for storing
Terraform state.

[blunderbuss]: https://github.com/googleapis/repo-automation-bots/tree/main/packages/blunderbuss
[dee-obs-team]: https://github.com/orgs/GoogleCloudPlatform/teams/dee-observability
[auto-label]: https://github.com/googleapis/repo-automation-bots/tree/main/packages/auto-label
[hdr-chk-lint]: https://github.com/googleapis/repo-automation-bots/tree/main/packages/header-checker-lint
[github-runners]: https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners
[gcb-app]: https://github.com/apps/google-cloud-build
[no-key]: https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions
