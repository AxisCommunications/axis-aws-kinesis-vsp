# syntax=docker/dockerfile:1
ARG IMAGE_TAG

FROM axisecp/kinesis-video-stream-application:$IMAGE_TAG as base

WORKDIR /opt/app/amazon-kinesis-video-streams-producer-sdk-cpp/build

COPY ./certificate_files/certificate.pem certificate_files/certificate.pem
COPY ./certificate_files/private.pem.key certificate_files/private.pem.key
COPY ./certificate_files/cacert.pem certificate_files/cacert.pem
COPY start_stream.sh .
