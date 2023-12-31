# Container Scanning

This analyzer is a Ruby gem that uses container scanner tools such as [Trivy](https://github.com/aquasecurity/trivy) to create reports that are parseable by GitLab. This project also depends on [Security report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas).

The resulting analyzer docker image is used with the [official template](https://docs.gitlab.com/ee/user/application_security/container_scanning/#configuration).

## Current Settings

You can configure container scanning by using the [available CI/CD variables](https://docs.gitlab.com/ee/user/application_security/container_scanning/#available-cicd-variables):

Please do not use scanner-specific variables that are not documented as being supported by the GitLab analyzer.

## Release

To release a new version:
1. Update `VERSION` in `lib/gcs/version.rb`
1. Merge changes

Then do one of the following

### Run the release task

This will run an interactive script that will guide you through the verification steps.

```shell
git checkout master && git pull
bundle install

# Release HEAD
bundle exec rake tag_release

# Release a specific commit
bundle exec rake 'tag_release[159129607454a52199b7ba4c7d47fa88cd20a370]'
```

### Release manually from project

1. Check the [commits](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/commits/master)
   and verify that they have changelog trailers (e.g. `Changelog: changed`)
   - If there commits which have user-facing changes but do not have a changelog, note down which ones.
   - After release pipeline is completed, open a merge requests to update [CHANGELOG.md](CHANGELOG.md)
     with any missing changelogs (if applicable)
1. Create a [new tag](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/tags) matching the
   version in [`lib/gcs/version.rb`](lib/gcs/version.rb)
1. A [tag pipeline](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/pipelines?scope=tags&page=1)
   will perform the release

### Reverting a release

In the event that an undesirable change is released accidentally, the following process
should be following to revert the release.

1. Revert the change with a new commit, using `Changelog: fixed`
1. Bump the patch version in `lib/gcs/version.rb` with a new commit
1. Tag the latest commit with the new version and allow the tag pipeline to perform a new release

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

A scheduled pipeline executed on the default (`master`) branch with a CI variable `TRIGGER_DB_UPDATE_FOR_MAJOR_VERSIONS`
set to a comma-separated list of major release versions (e.g.: '4,5') will trigger a pipeline that will execute a single
job in the `maintenance` stage called `trigger-db-update`.

This job will find the last 100 [releases](https://docs.gitlab.com/ee/api/graphql/reference/#projectreleases), and
trigger one pipeline for each major version using the `tagName` of the latest release as the `ref=` argument.

This job depends on the `CS_TOKEN`. The variable must *not* be protected because the job runs on tag builds, not
branch, and when it first runs the tag is not protected. We could move to a `vM.m.p` pattern and protect `v*` tags but
this is not currently in place.

#### Scanner updates

Follow the steps in [how to update scanners](doc/howto/update-scanners.md)

## License

See the [LICENSE](LICENSE) file for more details.

## Contributing

Contributions are welcome, see the [CONTRIBUTING.md](CONTRIBUTING.md) for more details.
