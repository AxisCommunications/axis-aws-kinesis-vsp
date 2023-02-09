#!/bin/bash

# Parse the input arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --clip-length) clip_length="$2"; shift ;;
        --use-tls) use_tls="$2"; shift ;;
    esac
    shift
done

# Verify mandatory parameters
if [ -z "$clip_length" ]; then
    echo "Input argument --clip-length is missing, please add it:"
    echo "--clip-length <lenght of clip in seconds to stream and download>"
    exit 1
fi

# Export env vars
set -o allexport
# shellcheck source=/dev/null
source .env
set +o allexport

echo "Getting temporary credentials"
aws_credential_provider=$(aws --profile default iot describe-endpoint --endpoint-type iot:CredentialProvider --output text)
token=$(curl --silent -H "x-amzn-iot-thingname:${AWS_KINESIS_STREAM_NAME}" --cert ${CERTIFICATE_PATH}/certificate.pem --key ${CERTIFICATE_PATH}/private.pem.key https://${aws_credential_provider}/role-aliases/${AWS_ROLE_ALIAS}/credentials --cacert ${CERTIFICATE_PATH}/cacert.pem)

# Export additional varaiables needed to run the commands towards AWS
export AWS_ACCESS_KEY_ID_TMP=$(jq --raw-output '.credentials.accessKeyId' <<< $token)
export AWS_SECRET_ACCESS_KEY_TMP=$(jq --raw-output '.credentials.secretAccessKey' <<< $token)
export AWS_SESSION_TOKEN_TMP=$(jq --raw-output '.credentials.sessionToken' <<< $token)

# Start the stream
echo "Starting Kinesis Video Stream"
if [ -z "$use_tls" ]; then
    docker-compose -H $DEVICE_IP:2375 up -d
else
    docker-compose --tlsverify -H $DEVICE_IP:2376 up -d
fi

# Get data endpoint for downloading clip
data_endpoint_json=$(aws kinesisvideo get-data-endpoint --stream-name ${AWS_KINESIS_STREAM_NAME} --api-name GET_DASH_STREAMING_SESSION_URL --region ${AWS_REGION})
data_endpoint=$(jq --raw-output '.DataEndpoint' <<< $data_endpoint_json)

# Wait for stream to finish
echo "Running stream for ${clip_length} seconds..."
sleep $((clip_length + 10))
fragment_selector_json='{"FragmentSelectorType": "SERVER_TIMESTAMP", "TimestampRange": {"StartTimestamp": '$(expr $(date +%s) - ${clip_length})', "EndTimestamp": '$(date +%s)'}}'

# Download clip
echo "Downloading video clip..."
aws kinesis-video-archived-media get-clip --stream-name ${AWS_KINESIS_STREAM_NAME} --clip-fragment-selector "${fragment_selector_json}" --endpoint-url ${data_endpoint} ./video.mp4

# Stop the stream
echo "Stopping stream"
if [ -z "$use_tls" ]; then
    docker-compose -H $DEVICE_IP:2375 down
else
    docker-compose --tlsverify -H $DEVICE_IP:2376 down
fi
