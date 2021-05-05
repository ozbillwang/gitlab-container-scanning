## Development guide

### Docker based development and testing

For building a new image with the ruby gem:

```
$ docker build -t gcs .
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
   1. Update the existing `Dockerfile` or adding a specific one.
   1. It might require updating `script/build.sh` to generalize the downloading of different packages. It would be great to have this logic based on `$SCANNER`.
   1. The new scanner should generate its own docker image instead of overwritting the root image.
   1. Create a new ruby file under `lib/gcs` and feel free to work on abstracting the code as you see fit.
1. Running stage:
   1. In case `$SCANNER` has not been set as a environment variable (not as an argument), set it with the scanner name. The default value is `trivy`.
1. Documentation:
   1. Although there is very little information that would have to be updated in this repository, the main GitLab repository has a couple places which might require change. Feel free to ask any member of this team for help on that.
