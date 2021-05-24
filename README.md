# Container Scanning

This analyzer is a Ruby gem that uses [Trivy](https://github.com/aquasecurity/trivy) to create reports that are parsable by GitLab. In addition to Trivy this project also depends on [Security report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas) and currently, this ruby gem runs within a docker container based on [ruby:2.7.3-slim](https://hub.docker.com/layers/ruby/library/ruby/2.7.3-slim/images/sha256-622020c80822135248c7e84e3bf4ac4447cc1f76a369fcc3cb24a876d0ec5345?context=explore). Therefore, the final docker image can be used through [gitlab-ci.yml](https://docs.gitlab.com/ee/ci/quick_start/index.html#create-a-gitlab-ciyml-file).

## Direct usage through gitlab-ci.yml

After becoming familiar with [how to use gitlab-ci.yaml](https://docs.gitlab.com/ee/ci/quick_start/index.html#create-a-gitlab-ciyml-file) as part of your project and making sure that there is a [build image](https://docs.gitlab.com/ee/topics/autodevops/customize.html#using-components-of-auto-devops) of your project, the following can be used:

```
container_scanning:
  stage: test
  image: registry.gitlab.com/gitlab-org/security-products/analyzers/container-scanning:latest
  allow_failure: true
  script:
    - gtcs scan
  artifacts:
    reports:
      container_scanning: gl-container-scanning-report.json
    paths: [gl-container-scanning-report.json]
```

## Current Settings

You can configure container scanning by using the following environment variables:

| Environment Variable           | Default       | Description |
| ------------------------------ | ------------- | ----------- |
| `ADDITIONAL_CA_CERT_BUNDLE`    | `""`          | Bundle of CA certs that you want to trust. |
| `CI_APPLICATION_REPOSITORY`    | `$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG` | Docker repository URL for the image to be scanned. |
| `CI_APPLICATION_TAG`           | `$CI_COMMIT_SHA` | Docker repository tag for the image to be scanned. |
| `DOCKER_IMAGE`                 | `$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG` | The Docker image to be scanned. If set, this variable overrides the `$CI_APPLICATION_REPOSITORY` and `$CI_APPLICATION_TAG` variables. |
| `TRIVY_INSECURE`              | `"false"`     | Allow [Trivy] to access secure Docker registries using HTTPS with bad (or self-signed) SSL certificates. |
| `TRIVY_PASSWORD`              | `""` | Password for accessing a Docker registry requiring authentication. |
| `TRIVY_USERNAME`                  | `""` | Username for accessing a Docker registry requiring authentication. |
| `DOCKERFILE_PATH`              | `Dockerfile`  | The path to the `Dockerfile` to be used for generating remediations. By default, the scanner looks for a file named `Dockerfile` in the root directory of the project, so this variable should only be configured if your `Dockerfile` is in a non-standard location, such as a subdirectory. See [Solutions for vulnerabilities](#solutions-for-vulnerabilities-auto-remediation) for more details. |
| `SECURE_LOG_LEVEL`             | `info`        | Set the minimum logging level. Messages of this logging level or higher are output. From highest to lowest severity, the logging levels are: `fatal`, `error`, `warn`, `info`, `debug`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10880) in GitLab 13.1. |
| `GIT_STRATEGY`                 | `none`     | Set to `fetch` when including `vulnerability-allowlist.yml` file. |

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
