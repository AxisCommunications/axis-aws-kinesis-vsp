no_proxy=$IP gst-launch-1.0 rtspsrc \
location="rtsp://$USERNAME:$PASSWORD@$IP/axis-media/media.amp" short-header=TRUE ! rtph264depay ! h264parse ! video/x-h264 !kvssink stream-name="$STREAM_NAME" storage-size=512 \
access-key="$ACCESS_KEY_ID" secret-key="$SECRET_KEY" aws-region="$REGION"

