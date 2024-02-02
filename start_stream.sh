#!/bin/bash
gst-launch-1.0 --no-fault rtspsrc \
        location="rtsp://$DEVICE_USERNAME:$DEVICE_PASSWORD@$DEVICE_IP/axis-media/media.amp" short-header=TRUE ! rtph264depay ! h264parse ! video/x-h264 !kvssink stream-name="$AWS_KINESIS_STREAM_NAME" storage-size=512 \
        aws-region="$AWS_REGION"
