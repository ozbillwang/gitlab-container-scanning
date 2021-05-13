## Development guide

### Docker based development and testing

For building a new image with the ruby gem:

```
$ docker build --build-arg SCANNER -t gcs .
```

Note that `trivy` is built by default by both not setting `$SCANNER` or setting it to `trivy`. To build a different scanner define `$SCANNER` as the following:

```
export SCANNER=myscanner
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

### Running tests within docker container

From within the container:
```
$ cd /home/gitlab/gcs
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
   1. Update `script/setup.sh` to generalize the downloading and placing of files required. Scanner selection is performed through `$SCANNER`. Note that each scanner will have its own docker image even if they share most of the source code.
   1. Create a new ruby file under `lib/gcs` similar to `trivy.rb` with the main call, and feel to adjust `environment.rb` and other files as needed.
1. Running stage:
   1. Similar to the previous stage, the running scanner will be based on `$SCANNER` which has been already set during the build stage. The default value is `trivy`.
1. Documentation:
   1. Although there is very little information that would have to be updated in this repository, the main GitLab repository has a couple places which might require changes. Feel free to ask any member of this team for help on that.
