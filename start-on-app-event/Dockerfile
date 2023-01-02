# syntax=docker/dockerfile:1

ARG ARCH

FROM axisecp/kinesis-video-stream-application:latest-$ARCH

RUN <<EOF
apt-get update
apt-get install -y \
  python3-pip
EOF

RUN pip3 install --no-cache-dir requests==2.27.1

WORKDIR /opt/app/amazon-kinesis-video-streams-producer-sdk-cpp/build

COPY ./app.py .
COPY ./start_stream_mkv.sh .
COPY ./json ./json
COPY ./xml ./xml

CMD ["python3", "app.py"]
