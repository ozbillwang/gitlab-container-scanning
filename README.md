# Container Scanning

This analyzer is a Ruby gem that uses [Trivy](https://github.com/aquasecurity/trivy) to create reports that are parsable by GitLab. In addition to Trivy this project also depends on [Security report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas) and currently, this ruby gem runs within a docker container based on [ruby:2.7.2-slim](https://hub.docker.com/layers/ruby/library/ruby/2.7.2-slim/images/sha256-4c103e549aad7ba3604c291130d666d349645004f28d5a86a800ff6c70c6c518?context=explore). Therefore, the final docker image can be used through [gitlab-ci.yml](https://docs.gitlab.com/ee/ci/quick_start/index.html#create-a-gitlab-ciyml-file).

## Direct usage through gitlab-ci.yml

After becoming familiar with [how to use gitlab-ci.yaml](https://docs.gitlab.com/ee/ci/quick_start/index.html#create-a-gitlab-ciyml-file) as part of your project and making sure that there is a [build image](https://docs.gitlab.com/ee/topics/autodevops/customize.html#using-components-of-auto-devops) of your project, the following can be used:

```
container_scanning:
  stage: test
  image: "<TBD>"
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
| `TRIVY_DEBUG`                   | `"false"`     | Set to true to enable more verbose output from klar. |
| `SECURE_LOG_LEVEL`             | `info`        | Set the minimum logging level. Messages of this logging level or higher are output. From highest to lowest severity, the logging levels are: `fatal`, `error`, `warn`, `info`, `debug`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10880) in GitLab 13.1. |

## License

See the [LICENSE](LICENSE) file for more details.

## Contributing

Contributions are welcome, see the [CONTRIBUTING.md](CONTRIBUTING.md) for more details.
