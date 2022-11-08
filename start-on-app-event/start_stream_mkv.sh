#!/bin/bash
gst-launch-1.0 -v filesrc location="$FILE_NAME" ! matroskademux name=demux ! h264parse !kvssink name=sink stream-name="$AWS_KINESIS_STREAM_NAME" access-key="$AWS_ACCESS_KEY_ID" secret-key="$AWS_SECRET_ACCESS_KEY" aws-region="$AWS_REGION"
