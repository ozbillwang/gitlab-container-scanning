# Gcs
+-------------------------------------------------------+
|                                                       |
|          Docker image (debian with ruby 2.7.2)        |
|                                                       |
|    +-------------+           +----------------+       |
|    |             |           |                |       |
|    | Gcs Gem     -------------   Trivy Binary |       |
|    |             |           |                |       |
|    +-------------+           +----------------+       |
|                                                       |
|                                                       |
|                                                       |
|                                                       |
+-------------------------------------------------------+

Gcs is a gem that uses Trivy to create reports that is parsable by Gitlab.
Gem itself doesn't have any scanning functionality it just adds simple functionality in top of Trivy such as
- remediations
- generating Gitlab parsable report
- allowlist.yml to ignore certain vulns (to be implemented)
- configuring certificate for offline environment

Everthing is shipped as a docker container so that gitlab-ci can use it

# Ci configuration

For now you can use following configuration to try scanning your project. Make sure your have a step where you build image of your project.

```
gcs_container_scanning:
  stage: test
  image: "registry.gitlab.com/caneldem/gcs:edge"
  allow_failure: true
  script:
    - gtcs scan
  artifacts:
    reports:
      container_scanning: gl-container-scanning-report.json
    paths: [gl-container-scanning-report.json]
```

# Available variables

You can [configure](#customizing-the-container-scanning-settings) container
scanning by using the following environment variables:

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

# Development

`docker build -t gcs . && docker run --rm -it  gcs bash` -> for interacting gcs gem locally `gtcs help` for list of commands

`docker build -t gcs . && docker run --rm -it --volume "$PWD:/gcs/" gcs bash` -> mounting source code to docker in case you want to alter code and quickly try your changes

`bundle exec rake unit_test` for unit tests

`bundle exec rake integration` for integration tests (make sure you have docker installed)

# Todos

- [x] Add json schema validation
- [x] Add remediation support
- [x] DOCKERFILE_PATH variable
- [x] Add DOCKERFILE_PATH variable
- [x] Add ADDITIONAL_CA_CERT_BUNDLE variable
- [x] Add tests for offline environment
- [x] Add more integration test for different image
- [] Add allowlist.yml support
- [] Proper project setup in case we go with this project


