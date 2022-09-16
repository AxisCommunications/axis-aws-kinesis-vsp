no_proxy=$IP_CAM gst-launch-1.0 rtspsrc \
location="rtsp://$USERNAME_CAM:$PASSWORD_CAM@$IP_CAM/axis-media/media.amp" short-header=TRUE ! rtph264depay ! h264parse ! video/x-h264 !kvssink stream-name="$STREAM_NAME" storage-size=512 \
access-key="$ACCESS_KEY_ID" secret-key="$SECRET_KEY" aws-region="$REGION"
