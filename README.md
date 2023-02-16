# AWS Kinesis Video Stream Application

The AWS Kinesis Video Stream Application can be run on a virtualization enabled
Axis camera as a container, making it possible to stream video to
[AWS Kinesis Video Streams](https://aws.amazon.com/kinesis/video-streams/). The
stream can thereafter be fed into other AWS services such as Rekognition to
perform image and or video analytics.

![diagram](./assets/diagram.png)

## Requirements

The following setup is supported:

- Camera
    - Chip: ARTPEC-{7-8} DLPU devices (e.g., Q1615 MkIII)
    - Firmware: 10.9 or higher
    - [Docker ACAP](https://github.com/AxisCommunications/docker-acap) installed and started, using TLS and SD card as storage

- Computer
    - OS: Linux/macOS running preferred shell, or Windows 10 with WSL2 installed to run Bash on Windows
    - AWS Account with
    [security credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) generated
        - [Option 1: Access key ID and Secret access key](#option-1-access-key-id-and-secret-access-key)
            - Access key ID
            - Secret access key
        - [Option 2: AWS IoT certificates](#option-2-aws-iot-certificates)
            - AWS IoT certificates
            - As an alternative to using the generated certificate to authenticate, additional temporary credentials can be generated from the certificate comprising a temporary access key ID, secret access key and session token.
- [Docker](https://docs.docker.com/get-docker/) with BuildKit enabled
    - [Docker Compose](https://docs.docker.com/compose/install/)

## Option 1: Access key ID and Secret access key

## Variables

To run the solution, a number of variables need to be added. These will be used for building or pulling the Docker image and
running it.

### Shell Variables

Add the image name as a shell variable so that it can be reused:

```sh
IMAGE_NAME=axisecp/kinesis-video-stream-application
```

Also, add the image tag:

```sh
IMAGE_TAG=latest-<armv7hf or aarch64>
```

where the image tag is `latest-armv7hf` for ARTPEC-7 and `latest-aarch64` for
ARTPEC-8 devices.

### Environment Variables

Before running the solution, environment variables need to be set up.
Create a file named `.env` in the root directory of this repository, it will contain data to communicate with the camera and
AWS. After creating the file, add the content below to the file and fill in the corresponding values:

```sh
# Camera specific variables
DEVICE_USERNAME=<camera username>
DEVICE_PASSWORD=<camera password>

# AWS related variables
AWS_KINESIS_STREAM_NAME=<AWS Kinesis video stream name>
AWS_REGION=<AWS region>
AWS_ACCESS_KEY_ID=<AWS access key ID>
AWS_SECRET_ACCESS_KEY=<AWS secret key>
```

## Install

The image can be retrieved by either pulling it from Docker Hub, or by building
it locally.

### From Docker Hub

Get the Docker image by pulling it from Docker Hub:

```sh
docker pull ${IMAGE_NAME}:${IMAGE_TAG}
```

### Build Locally

Add the architecture for the Docker image as a shell variable, depending on the camera
system-on-chip. Use `arm32v7` for ARTPEC-7 devices:

```sh
ARCH=arm32v7
```

and `arm64v8` for ARTPEC-8:

```sh
ARCH=arm64v8
```

Once the shell variables have been added, the Docker image can be built:

```sh
docker buildx build --tag ${IMAGE_NAME}:${IMAGE_TAG} --build-arg ARCH --build-arg KVS_CPP_PRODUCER_SDK_TAG=v3.3.1 .
```

## Option 2: AWS IoT certificates

Kinesis Video Streams do not support certificate-based authentication, however, AWS IoT has a credentials provider that allows
you to use the built-in X.509 certificate as the unique device identity to authenticate AWS requests.

### Prerequisites

- Create an IoT Thing Type and an IoT Thing
- Create an IAM Role to be assumed by IoT
- Create and configure the X.509 certificate

AWS provides [documentation](https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/how-iot.html) for how to set the above
prerequisites up. However, to simplify the process of setting up an IAM Role assumed by IoT, policies, certificates etc, a script
is provided.

If the prerequisites are set up by following the
[documentation](https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/how-iot.html) from AWS step 2 below can be skipped.

In addition the steps below make use of the following tools to various extent:

- **AWS CLI**.
    - [Getting started with the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
        - Ensure to choose a region that supports Kinesis Video Streams.
- **jq**, a lightweight command-line JSON processor.
    - Installation and getting started instructions can be found [here](https://stedolan.github.io/jq/).

### Creating the certificate files

1. Create a file named `.env` in the `x509-authentication` directory of this repository, it will contain data to communicate with
    the camera and AWS. Add the content below to the file and fill in the corresponding values:

    > For the `generate_certificate.sh` script and Docker Compose to pick up the environment variables the file needs to be named `.env`
    **and** be placed in the `x509-authentication` directory.

    ```sh
    DEVICE_USERNAME=<camera username>
    DEVICE_PASSWORD=<camera password>
    GST_PLUGIN_PATH=/opt/app/amazon-kinesis-video-streams-producer-sdk-cpp/build
    PROXY=<proxy address, needed if camera is behind a proxy>

    # AWS related variables
    AWS_KINESIS_STREAM_NAME=<AWS Kinesis video stream name>
    AWS_REGION=<AWS region>
    AWS_CREDENTIAL_PROVIDER=<AWS credential provider, see next step for how to fetch it>
    AWS_ROLE_ALIAS=<Pick a name for the AWS Role Alias>

    # Additional AWS variables needed for generating certificate
    AWS_THING=$AWS_KINESIS_STREAM_NAME
    AWS_THING_TYPE=<Pick a name for the AWS Thing Type>
    AWS_ROLE=<Pick a name for the AWS Role>
    AWS_IAM_POLICY=<Pick a name for the AWS IAM Policy>
    AWS_IOT_POLICY=<Pick a name for the AWS IOT Policy>
    AWS_ROOT_CA_ADDRESS=https://www.amazontrust.com/repository/SFSRootCAG2.pem
    ```

    It's required that the value of `AWS_THING` is identical to the value of `AWS_KINESIS_STREAM_NAME`.

    To fetch the credentials provider the following command can be used:

    ```sh
    aws --profile default iot describe-endpoint --endpoint-type iot:CredentialProvider --output text
    ```

2. Step into the `certificate_files` directory and run the following command to generate certificate and keys:

    > This step can be skipped if setting up the certificate manually according to the [AWS documentation](https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/how-iot.html).

    If `AWS CLI` is configured with `output = json` the script can be run as:

    ```sh
    ./generate_certificate.sh ../.env
    ```

    If another configuration is set, `AWS_DEFAULT_OUTPUT="json"` can be added to the call instead, i.e.:

    ```sh
    AWS_DEFAULT_OUTPUT="json" ./generate_certificate.sh ../.env
    ```

    > Currently the script only supports a profile named `default` for the calls made towards AWS CLI. If you like it to use another profile read about [Named profiles for the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) in the AWS documentation and update the script accordingly.

### Creating the image

There's two options for how to run an image using the generated certificates. Either by building the certificates into an image or by generation temporary credentials from the certificate.

To build the certificates into the image the following steps needs to be performed:
1. Step back into the `x509-authentication` directory and build an image.

    - To build the image first set the following environment variables in your shell:

        ```sh
        export IMAGE_NAME=<Choose a name to tag the new image running with certificates with>
        export IMAGE_TAG=<Choose either latest-armv7hf or latest-aarch64>
        export DEVICE_IP=<camera IP>
        ```

    - Then run the build command:

        ```sh
        docker buildx build --tag ${IMAGE_NAME}:${IMAGE_TAG} --build-arg IMAGE_TAG=$IMAGE_TAG .
        ```

2. Create the Kinesis Video Stream.

    If the policy is set with the script above or according to the [AWS documentation](https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/how-iot.html),
    permission will **not** be set for `KinesisVideo:CreateStream` action. I.e. the stream will have to be created manually.

    ```sh
    aws kinesisvideo create-stream --data-retention-in-hours 2 --stream-name <name of the stream used in above steps>
    ```

    >The stream name must be the same as the name of the Thing created earlier.


The second option is to use temporary credentials generated from the certificate files, with this option the image won't need to be rebuild. To use this option the following steps needs to be performed:

1. Generate the temporary credentials by running the `generate_temporary_credentials.sh` script in the `x509-authentication/certificate` folder similar to how the certificate was generated:
    
    ```sh
    ./generate_temporary_credentials.sh ../.env
    ```

    The script will echo the temporary credentials and environment variables to set:
    
    ```sh
    √ ~ % ./generate_temporary_credentials.sh ../.env
    Temporary credentials created with an expiration date set to:2023-02-15T19:54:53Z
    
    Run the following command in your shell to export the temporary credentials so that they can be picked up by docker compose.
    export AWS_ACCESS_KEY_ID_TMP=********************
    export AWS_SECRET_ACCESS_KEY_TMP=******************
    export AWS_SESSION_TOKEN_TMP=************************
    ```

2. Follow the instructions and export the variables:
    
    ```sh
    export AWS_ACCESS_KEY_ID_TMP=********************
    export AWS_SECRET_ACCESS_KEY_TMP=******************
    export AWS_SESSION_TOKEN_TMP=************************
    ```
    
    > The actual values are much longer than the substitutes above `*****` 
    
3. When using the temporary credentials the original image from [Option 1: Access key ID and Secret access key](#option-1-access-key-id-and-secret-access-key) can be used with one minor update in to the `docker-compose.yml` file needed to start the Kinesis stream.

    - In the root folder of the repo update the `docker-compose.yml` to use the temporary credentials set in the exported environment variables above, in addition including the `AWS_SESSION_TOKEN`.
     
     - Update the environment variables in the `docker-compose` file:

     ```
     # From:
     AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
     AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
     
     # To:
     AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID_TMP
     AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY_TMP
     AWS_SESSION_TOKEN: $AWS_SESSION_TOKEN_TMP
     ```
 
## Run on the Camera

### Save and Load the Image to the Camera

Add the camera's IP address as a shell variable:

```sh
DEVICE_IP=<camera IP>
```

Clear Docker memory:

```sh
docker --tlsverify -H $DEVICE_IP:2376 system prune --all --force
```

If you encounter any TLS related issues, please see the TLS setup chapter regarding the `DOCKER_CERT_PATH` environment variable
in the [Docker ACAP repository](https://github.com/AxisCommunications/docker-acap).

The image can now be saved and loaded to the camera:

```sh
docker save ${IMAGE_NAME}:${IMAGE_TAG} | docker --tlsverify -H $DEVICE_IP:2376 load
```

### Starting the Container

To start the container you can use Docker Compose:

```sh
docker-compose --tlsverify -H $DEVICE_IP:2376 up
```

or:

```sh
docker-compose --tlsverify -H $DEVICE_IP:2376 up -d
```

to run in detached (background) mode.

Once the `docker-compose` command has been run, an RTSP stream is set up with the
`start_stream.sh` script. The AWS GStreamer plugin kvssink sends media based on
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
