# GitHub configurations and bots

The repo defines templates for new [pull requests], [bugs] and [features].
The configurations include the following bots:

* [Blunderbuss]: Auto-assigner of a Github users to pull requests and issues
* [Header checker]: Presubmit check that all files with configured extensions have the proper copyright header
* [Conventional commit lint]: Presubmit check that all commit messages in PR follow the [convention]
* [Snippets]: Scanner for possible code sample snippets to integrate them into Google Cloud documentation
* [Trusted contributors]: Integrator for Github application trusted access to the repo

For information about the customized workflow, see [workfows/README]

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
