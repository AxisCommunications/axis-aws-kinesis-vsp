ARG ARCH

FROM $ARCH/ubuntu:18.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libssl-dev libcurl4-openssl-dev liblog4cplus-dev libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-base-apps \
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly gstreamer1.0-tools \
    cmake pkg-config m4 git g++-5

WORKDIR /opt/app/

RUN git clone --recursive https://github.com/awslabs/amazon-kinesis-video-streams-producer-sdk-cpp.git

WORKDIR /opt/app/amazon-kinesis-video-streams-producer-sdk-cpp/build

ENV CC=/usr/bin/gcc-5
ENV CXX=/usr/bin/g++-5

RUN cmake .. -DBUILD_GSTREAMER_PLUGIN=TRUE && make

FROM $ARCH/ubuntu:18.04

COPY --from=0 /opt/app/amazon-kinesis-video-streams-producer-sdk-cpp/ /opt/app/amazon-kinesis-video-streams-producer-sdk-cpp/

WORKDIR /opt/app/amazon-kinesis-video-streams-producer-sdk-cpp/build/

RUN apt update && apt install -y --no-install-recommends \
    gstreamer1.0-tools libssl-dev gstreamer1.0-rtsp \
    gstreamer1.0-plugins-bad curl
