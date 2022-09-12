# Axis AWS Kinesis Video Streams Producer

The Axis AWS Kinesis Video Streams Producer can be run on an Axis camera as a container, making it possible to stream video to AWS Kinesis Video Streams. The stream can thereafter be fed into other AWS services such as Rekognition to perform analytics.

## Compatibility

The following camera setup is supported

- ARTPEC-7/8 system-on-chip
- Firmware version 10.7 or greater
- Container capable camera with SD card

## Prerequisites

- [Docker Compose](https://github.com/AxisCommunications/docker-compose-acap) installed and started with TLS and SD card storage selected
- AWS Account with security credentials generated
  - Access key ID
  - Secret key
- Kinesis video stream created
- Docker
- Docker Compose

## Install

The image can be retrieved by either pulling it from Dockerhub, or by building it locally.

### From Dockerhub

Get the Docker image by pulling it from Dockerhub

```
docker pull $REPO/$IMAGE_NAME:$ARCH
```

### Build Locally

#### Add the Buildtime Environment Variables

The camera architecture should be added as a buildtime environment variable, so that it corresponds to the target device's hardware.

Use arm32v7 for ARTPEC-7 devices:

```
ARCH=arm32v7
```

and arm64v8 for ARTPEC-8:

```
ARCH=arm64v8
```

The image name will also be added as an environment variable:

```
IMAGE_NAME=kinesis-vsp
```

#### Build the Image

Once the environment variables have been added, the docker image can be built:

```
docker build -t $IMAGE_NAME . --build-arg ARCH
```

## Run on the Camera

### Install Docker Compose ACAP Application

It is recommended to install the [Docker Compose ACAP application](https://github.com/AxisCommunications/docker-compose-acap). It enables you to run Docker and Docker Compose commands from the camera's shell.

```
docker run --rm axisecp/docker-compose-acap:latest-<armv7hf/aarch64> $IP <root password> install
```

Where you use the image tag 'latest-armv7hf' for ARTPEC-7 and 'latest-aarch64' for an ARTPEC-8 device.

### Runtime Environment Variables

Before running the solution, some environment variables need to be set up.
This is both to specify the camera IP and for the container to find the correct Kinesis stream in AWS. The variables can also be set up directly into the docker-compose.yml file, depending on how you want your setup configured.

```
IP=<camera IP>
USERNAME=<camera root username>
PASSWORD=<camera root password>

STREAM_NAME=<Kinesis video stream name>
REGION=<AWS region>
ACCESS_KEY_ID=<AWS access key ID>
SECRET_KEY=<AWS secret key>
```

### Save and Load to the Camera

The image can now be saved and loaded to the camera.

```
docker save $IMAGE_NAME | docker load -H $IP:2376 --tls-verify
```

### Starting the Container

To start the container you can use docker compose

```
docker-compose up -H $IP:2376 --tls-verify
```

__or__

```
docker-compose up -d -H $IP:2376 --tls-verify
```

to run in detached (background) mode.

## Verify That the Kinesis Video Stream is Successfully Running

The most straightforward way to verify that the stream from the camera actually reaches Kinesis Video Streams is to do it from the AWS UI.

1. Log in to your AWS account
2. Search for and go to the Kinesis Video Streams service
3. Select the correct region and Kinesis video stream in the list.
4. Click the 'Media Playback' button
5. If everything is set up correctly, the stream should show up. Wait a number of seconds since there might be a delay. 

## Known Limitations
When streaming to AWS Kinesis Video Streams there is a latency which can be affected by the selected AWS region, network setup and video resolution.
