# Container Scanning

This analyzer is a Ruby gem that uses container scanner tools such as [Trivy](https://github.com/aquasecurity/trivy) to create reports that are parseable by GitLab. This project also depends on [Security report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas).

The resulting analyzer docker image is used with the [official template](https://docs.gitlab.com/ee/user/application_security/container_scanning/#configuration).

## Current Settings

You can configure container scanning by using the [available CI/CD variables](https://docs.gitlab.com/ee/user/application_security/container_scanning/#available-cicd-variables):

Please do not use scanner-specific variables that are not documented as being supported by the GitLab analyzer.

## Changelog guidelines

All commits that get merged to the default branch should include the Changelog Git trailer.
Make sure to follow [changelog guidelines](https://docs.gitlab.com/ee/development/changelog.html#what-warrants-a-changelog-entry).
Commit that just updates the `VERSION` in `lib/gcs/version.rb` or any non-user facing changes should include the Changelog trailer value as `other`.

## Release

To release a new version:
1. Update `VERSION` in `lib/gcs/version.rb`
1. Merge changes
1. Create a tag matching `VERSION`
1. Create a release matching `VERSION`
   1. Add a link to the `CHANGELOG.md` file pointing to the `VERSION` anchor.

### Available image tags

- `edge`: HEAD of default branch
- `latest`: latest tag build
- `MAJOR.MINOR.PATCH`: latest tag/schedule build matching the given version
- `MAJOR`: latest tag/schedule build matching the given major version number

### Image updates

The vulnerabilities database is included in the docker image. In order to provide the latest
advisories, a daily build of the latest [release](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/releases)
is triggered and the resulting images are pushed to the
[container registry](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/container_registry)
under the following tags:

- `MAJOR`: current major version (e.g.: `4`)
- `MAJOR.MINOR`: current major version (e.g.: `4.1`)
- `MAJOR.MINOR.PATCH`: latest version (e.g.: `4.1.7`)
- `latest`: default tag when pulling an image without specifying a tag

A scheduled pipeline executed on the default (`master`) branch with a CI variable `TRIGGER_DB_UPDATE` set to any value
will trigger a pipeline that will execute a single job in the `maintenance` stage called `trigger-db-update`. This job
will find the [last released version(https://docs.gitlab.com/ee/api/releases/#list-releases)] and trigger a pipeline
using the tag of the latest release as a ref.

This job depends on the `GITLAB_TOKEN`. The variable must *not* be protected because the job runs on tag builds, not
branch, and when it first runs the tag is not protected. We could move to a `vM.m.p` pattern and protect `v*` tags but
this is not currently in place.

## License

See the [LICENSE](LICENSE) file for more details.

## Contributing

Contributions are welcome, see the [CONTRIBUTING.md](CONTRIBUTING.md) for more details.
