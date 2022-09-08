# Axis AWS Kinesis Video Streams Producer

The Axis AWS Kinesis Video Streams Producer can be run on an Axis camera as a container, making it possible to stream video to AWS Kinesis Video Streams. The stream can thereafter be fed into other AWS services such as Rekognition to perform analytics.

## Compatibility

The following camera setup is supported

- ARTPEC-7/8 system-on-chip
- Firmware

## Prerequisites

- Docker Compose ACAP installed and started
- AWS Account with credentials
  - Access key ID
  - Secret key
- Kinesis video stream created

## Install

### From Dockerhub

```
docker pull $REPO/$IMAGE_NAME:$ARCH
```

### Build Locally

#### Add the buildtime environment variables

The camera architecture should be added as a buildtime environment variable, so that it corresponds to the target device's hardware.

Use arm32 for ARTPEC-7 devices

```
ARCH=arm32v7
```

and arm64v8 for ARTPEC-8.

```
ARCH=arm64v8
```

#### Build the image

```
docker build -t kinesis_vsp . --build-arg ARCH
```

## Run on Camera

Before running the solution, some environment variables need to be set up.

```
IP=<camera IP>
STREAM_NAME=<Kinesis video stream name>
REGION=<aws-region>
ACCESS_KEY_ID=<AWS access key ID>
SECRET_KEY=<AWS secret key>
```

To start the container you can use docker compose

```
docker-compose up
```

or

```
docker-compose up -d
```

to run in detached mode (background).


## Verify that the Kinesis Video Stream is successfully set up

The most straightforward way to verify that the stream from the camera actually reaches Kinesis video streams is to do it from the AWS UI. 

1. Log in to your AWS account
2. Search for and go to the Kinesis Video Streams service
3. Select the correct region and kinesis video stream in the list.
4. Click the 'Media Playback' button
5. If everything is set up correctly, the stream should show up. Wait up to 10 seconds since there might be a delay. 

## Known Limitations
