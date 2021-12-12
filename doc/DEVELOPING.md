## Development guide

### Docker based development and testing

For building a new image with the ruby gem:

```
$ docker build --build-arg SCANNER -t gcs .
```

Note that `trivy` is built by default by both not setting `$SCANNER` or setting it to `trivy`. To build a different scanner define `$SCANNER` as the following:

```
export SCANNER=trivy

export SCANNER=grype
```

For creating and accessing a new container based on the `gcs` image:

```
$ docker run --rm -it gcs bash
```

Similar to the above but mounting the source code for fast development:

```
$ docker run --rm -it --volume "$PWD:/home/gitlab/gcs/" gcs bash
```

When inside the container the following provides a list of commands:

```
$ gtcs help
```

### Environment variables inside docker container

Specify the CI/CD environment variables from the [documentation](https://docs.gitlab.com/ee/user/application_security/container_scanning/#available-cicd-variables) either for the session with `export`, or specify them before the CLI command.

Example: Increase the debug output with the `SECURE_LOG_LEVEL` variable.

```
$ export SECURE_LOG_LEVEL=debug

$ gtcs scan ruby:3.0.0

# OR

$ SECURE_LOG_LEVEL=debug gtcs scan ruby:3.0.0
```

### Running tests within docker container

From within the container:
```
$ cd /home/gitlab/gcs
$ sudo apt-get update && sudo apt-get install -y -q build-essential
$ bundle
```

Unit tests:

```
$ bundle exec rake unit_test
```

Integration tests:

```
$ sudo ./script/setup_integration
$ bundle exec rake integration_test
```


### Running tests without a docker container

In case `ruby` is not installed, we recommend using `asdf` as the following:
   1. [Install `asdf`](https://asdf-vm.com/#/core-manage-asdf?id=install)
   1. Create `.tool-versions` file and add `ruby x.x.x` where `x.x.x` is the version which can be found in the [Dockerfile](../Dockerfile)
   1. Run `$ asdf install`
   1. Run `$ bundle`

Unit tests:

```
$ bundle exec rake unit_test
```

Integration tests:

```
bundle exec rake integration
```

### Updating the code for new scanners

At the moment adding scanners requires the following:

1. Build stage:
   1. Update `script/setup.sh` to support fetching and placing of files required by the new scanner. Scanner selection is performed through `$SCANNER`. Note that each scanner will have its own docker image even if they share most of the source code. If applicable add a new version file similar to `version/TRIVY_VERSION` as those can be accessible from the scope of `script/setup.sh`.
   1. Create a new ruby file under `lib/gcs` similar to `trivy.rb` with the main call to the new scanner.
   1. Create a template under `lib/template` matching your scanner name. This is used to create a report suitable for ingestion by GitLab based on the output of your scanner.
   1. In case it has not been created, add a new anchor and new build and test pipeline jobs as the following example:
   ```
   .new_scanner:
     allow_failure: true
     variables:
       SCANNER: new_scanner

   # Which will be further used by all new_scanner related jobs

   build-new_scanner-image:
     extends:
       - .build-tmp-image
       - .new_scanner
   ```
1. Running stage:
   1. Similar to the previous stage, the running scanner will be based on `$SCANNER` which has been already set during the build stage. The default value is `trivy`. As the build stage creates/updates a docker image, this image can be used for both standalone and for the tests executed as part of the pipeline. In case they haven't been add, follow the existing jobs related to the integration test:

   ```
   alpine new scanner:
     extends:
       - .alpine_test
       - .new_scanner

   # Note that it also relies on the anchor created in the previous step
   ```
1. Documentation:
   1. Although there is very little information that would have to be updated in this repository, the main GitLab repository has a couple places which might require changes. It is recommended to go through [the existing documentation](https://docs.gitlab.com/ee/user/application_security/container_scanning/#container-scanning) as it can help understanding which kind of information is expected as part of the integration. Feel free to ask any member of this team for help on that.
