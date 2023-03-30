# theos-docker

Docker image with theos and theos-jailed based on Ubuntu 20.04. Built to be used on CI.

## Building

```
docker build --tag theos-docker:1.0 .
```

## Debug usage

Find the newly built image with

```
docker images
```

and then take the image ID of the fresh one and insert it into

```
docker run -i -t <image-id> /bin/bash
```
