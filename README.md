# theos-docker

Docker image with theos and theos-jailed based on Ubuntu 20.04. Built to be used on CI.

## Building

```bash
docker build --tag theos-docker:11.4 .
```

The Docker image is bundled with a single iOS SDK. The default is iOS 11.4. To change this, set the build argument `SDK` to something from [the available patched iOS SDKs](https://github.com/theos/sdks) when building the Docker image.

```bash
docker build --build-arg SDK=iPhoneOS14.5 --tag theos-docker:14.5 .
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
