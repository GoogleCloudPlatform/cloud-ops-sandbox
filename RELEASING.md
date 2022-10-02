# Releasing

Each release stores Terraform configuration, application configurations and
Sandbox CLI as a git tag in this repository.
The current process releases minor and patch versions of Cloud Ops Sandbox.
The default (`main`) branch holds up to date _next minor release_ version of
Cloud Ops Sandbox. Latest and previous minor release versions are maintained
in dedicated branches. The branch names follow the pattern `release/X.Y` where
`X` is a major version number (currently is `0`) and `Y` is a minor version
number.

## Release Process

* Push a tag with the name of the next minor release version i.e.
`release/X.Y.0` to the default (`main`) branch to release the next minor
version of Cloud Ops Sandbox.
The push will trigger the [release workflow][1] that will run all e2e
validations and will create the release branch with the name `release/X.Y`
taken of the from the tag.
* Push a tag with the name of the next patch release version i.e.
`release/X.Y.Z` to the release branch with the name `release/X.Y` to release
the next patch version of Cloud Ops Sandbox. The push will trigger the [same][1]
workflow that will work similarly but will skip the step of creating new branch.

## Reverting releases

If there is a problem in the released new patch version. Work to resolve the
problems and release the next patch version that fixes the issues.
If a problem is discovered in releasing a new minor version, you can manually
delete the new created release branch (remember its name will be `release/0.F`)
where `F` is the number of the "bad" minor release. After fixing problems
"move" the release tag to the good commit in the default (`main`) branch. Use
`git push origin release/0.F --force` command to move the tag.

## Version Names

Cloud Ops Sandbox uses [semantic versioning][2] convention. Please, do not
prefix the version number with any letter (e.g. "v0.10.1") is invalid.

[1]: https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/.github/workflows/release.yml
[2]: https://semver.org/
