# Axis AWS Kinesis Video Streams Producer

The Axis AWS Kinesis Video Streams Producer can be run on an Axis camera as a container, making it possible to stream video to AWS Kinesis Video Streams. The stream can thereafter be fed into other AWS services such as Rekognition to perform analytics.

## Compatibility

The following camera setup is supported

- ARTPEC-7/8 system-on-chip
- Firmware version 10.7 or greater
- Container capable camera with SD card

## Prerequisites

- [Docker ACAP](https://github.com/AxisCommunications/docker-acap) installed and started with TLS and SD card storage selected
- AWS Account with security credentials generated
  - Access key ID
  - Secret key
- Kinesis video stream created
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Environment Variables

The camera architecture should be added as an environment variable, so that it corresponds to the target device's hardware.

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

Finally, add the camera IP address to your local environment variables:

```
IP_CAM=<camera IP>
```

## Install

The image can be retrieved by either pulling it from Dockerhub, or by building it locally.

### From Dockerhub

Get the Docker image by pulling it from Dockerhub:

```
docker pull axisecp/$IMAGE_NAME:latest-$ARCH
```

### Build Locally

Once the environment variables have been added, the docker image can be built:

```
docker build -t $IMAGE_NAME . --build-arg ARCH
```

## Run on the Camera

### Runtime Environment Variables

Before running the solution, additional environment variables need to be set up. Add the values to the variables located in the __.env__ file. They are needed for communicating with the camera and AWS. The values can also be added directly in the docker-compose.yml file, depending on how you want your setup configured.

### Install the Docker ACAP Application

Make sure that the [Docker ACAP application](https://github.com/AxisCommunications/docker-acap) is installed on the camera. To install it, you can run:

```
docker run --rm axisecp/docker-acap:latest-<armv7hf / aarch64> $IP_CAM <camera password> install
```

where you use the image tag 'latest-armv7hf' for ARTPEC-7 and 'latest-aarch64' for an ARTPEC-8 device.

### Save and Load the Image to the Camera

The image can now be saved and loaded to the camera.

```
docker save $IMAGE_NAME | docker --tlsverify -H $IP_CAM:2376 load
```

### Starting the Container

To start the container you can use docker compose

```
docker-compose --tlsverify -H $IP_CAM:2376 up
```

__or__


```
docker-compose --tlsverify -H $IP_CAM:2376 up -d
```

to run in detached (background) mode.

## Verify That the Kinesis Video Stream is Successfully Running

The most straightforward way to verify that the stream from the camera actually reaches Kinesis Video Streams is to do it from the AWS UI.

1. Log in to your AWS account.
2. Search for and go to the Kinesis Video Streams service.
3. Make sure that you are in the correct AWS region, and select the Kinesis video stream in the list.
4. Click the 'Media Playback' button.
5. If everything is set up correctly, the stream should show up. Wait a number of seconds since there might be a delay. 

## Known Limitations
When streaming to AWS Kinesis Video Streams there is a latency which can be affected by the selected AWS region, network setup and video resolution.
