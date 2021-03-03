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
$ docker run --rm -it --volume "$PWD:/gcs/" gcs bash
```

When inside the container the following provides a list of commands:

```
$ gtcs help
```

### Running tests without a docker container

Unit tests:

```
$ bundle exec rake unit_test
```

Integration tests:

```
bundle exec rake integration
```
