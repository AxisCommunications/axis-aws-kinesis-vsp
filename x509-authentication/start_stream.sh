#!/bin/bash

gst-launch-1.0 rtspsrc \
location="rtsp://$DEVICE_USERNAME:$DEVICE_PASSWORD@$DEVICE_IP/axis-media/media.amp" short-header=TRUE ! rtph264depay ! h264parse ! video/x-h264 ! kvssink stream-name="$AWS_KINESIS_STREAM_NAME" storage-size=512 \
iot-certificate="iot-certificate,endpoint=$AWS_CREDENTIAL_PROVIDER,cert-path=$GST_PLUGIN_PATH/certificate_files/certificate.pem,key-path=$GST_PLUGIN_PATH/certificate_files/private.pem.key,ca-path=$GST_PLUGIN_PATH/certificate_files/cacert.pem,role-aliases=$AWS_ROLE_ALIAS" aws-region="$AWS_REGION"
