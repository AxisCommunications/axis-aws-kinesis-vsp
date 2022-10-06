# AWS Kinesis Video Stream Application

The AWS Kinesis Video Stream Application can be run on a virtualization enabled
Axis camera as a container, making it possible to stream video to
[AWS Kinesis Video Streams](https://aws.amazon.com/kinesis/video-streams/). The
stream can thereafter be fed into other AWS services such as Rekognition to
perform image and or video analytics.

## Requirements

The following setup is supported:

- Camera
  - Chip: ARTPEC-{7-8} DLPU devices (e.g., Q1615 MkIII)
  - Firmware: 10.9 or higher
  - [Docker ACAP](https://github.com/AxisCommunications/docker-acap) installed and started, using TLS and SD card as storage

- Computer
  - AWS Account with
[security credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) generated
    - Access key ID
    - Secret key
  - [Docker](https://docs.docker.com/get-docker/)
  - [Docker Compose](https://docs.docker.com/compose/install/)

## Environment Variables

Add the image name as a shell variable so that it can be reused:

```sh
IMAGE_NAME=kinesis-video-stream-application
```

Also, add the camera's IP address:

```sh
DEVICE_IP=<camera IP>
```

## Install

The image can be retrieved by either pulling it from Docker Hub, or by building
it locally.

### From Docker Hub

Get the Docker image by pulling it from Docker Hub:

```sh
docker pull axisecp/$IMAGE_NAME:latest-<armv7hf or aarch64>
```

where the image tag is 'latest-armv7hf' for ARTPEC-7 and 'latest-aarch64' for
ARTPEC-8 devices.

### Build Locally

Add the architecture for the Docker image, depending on the camera
system-on-chip. Use arm32v7 for ARTPEC-7 devices:

```sh
ARCH=arm32v7
```

and arm64v8 for ARTPEC-8:

```sh
ARCH=arm64v8
```

Once the environment variables have been added, the docker image can be built:

```sh
docker build -t $IMAGE_NAME . --build-arg ARCH
```

## Run on the Camera

### Runtime Environment Variables

Before running the solution, additional environment variables need to be set up.
Add the values to the variables located in the __.env__ file. They are needed
for communicating with the camera and AWS. The values can also be added directly
in the docker-compose.yml file, depending on how you want your setup configured.

### Save and Load the Image to the Camera

The image can now be saved and loaded to the camera:

```sh
docker save $IMAGE_NAME | docker --tlsverify -H $DEVICE_IP:2376 load
```

### Starting the Container

To start the container you can use docker compose:

```sh
docker-compose --tlsverify -H $DEVICE_IP:2376 up
```

or:

```sh
docker-compose --tlsverify -H $DEVICE_IP:2376 up -d
```

to run in detached (background) mode.

Once the docker-compose command has been run, an RTSP stream is set up with the
start_stream.sh script. The AWS Gstreamer plugin kvssink sends media based on
the Matroska container format to AWS Kinesis Video Streams. The plugin is set up
with default values, however these values can be modified according to the
[kvssink parameter reference](https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/examples-gstreamer-plugin-parameters.html)
.

## Verify That the Kinesis Video Stream is Successfully Running

The most straightforward way to verify that the stream from the camera actually
reaches Kinesis Video Streams is to do it from the AWS UI.

1. Log in to your AWS account.
2. Search for and go to the Kinesis Video Streams service.
3. Make sure that you are in the correct AWS region, and select the Kinesis
video stream in the list.
4. Click the 'Media Playback' button.
5. If everything is set up correctly, the stream should show up. Wait a number
of seconds since there might be a delay.

## Known Limitations

When streaming to AWS Kinesis Video Streams there is a latency which can be
affected by the selected AWS region, network setup and video resolution.
