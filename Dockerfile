# syntax=docker/dockerfile:1

ARG ARCH

FROM $ARCH/ubuntu:18.04 as base

RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends \
  libssl-dev \
  libcurl4-openssl-dev \
  liblog4cplus-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-plugins-base-apps \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-tools \
  ca-certificates \
  cmake \
  pkg-config \
  m4 \
  git \
  g++-5
rm -rf /var/lib/apt/lists/*
EOF

WORKDIR /opt/app/

RUN git clone --recursive https://github.com/awslabs/amazon-kinesis-video-streams-producer-sdk-cpp.git

WORKDIR /opt/app/amazon-kinesis-video-streams-producer-sdk-cpp/build

ENV CC=/usr/bin/gcc-5
ENV CXX=/usr/bin/g++-5

RUN <<EOF
cmake .. -DBUILD_GSTREAMER_PLUGIN=TRUE
make
EOF

FROM $ARCH/ubuntu:18.04

COPY --from=base /opt/app/amazon-kinesis-video-streams-producer-sdk-cpp/ /opt/app/amazon-kinesis-video-streams-producer-sdk-cpp/

WORKDIR /opt/app/amazon-kinesis-video-streams-producer-sdk-cpp/build/

RUN <<EOF
apt-get update
apt-get install -y gstreamer1.0-tools libssl-dev gstreamer1.0-rtsp gstreamer1.0-plugins-bad
EOF

COPY start_stream.sh .
