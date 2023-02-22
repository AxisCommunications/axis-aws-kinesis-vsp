#!/bin/bash

if [ -z "$1" ]; then
    echo "Please add the path to the .env file as an argument"
    exit 1
fi

ENV_FILE_PATH="$1"

# Export env vars
set -o allexport
# shellcheck source=/dev/null
source "$ENV_FILE_PATH"
set +o allexport

token=$(curl --silent -H "x-amzn-iot-thingname:${AWS_KINESIS_STREAM_NAME}" --cert certificate.pem --key private.pem.key "https://${AWS_CREDENTIAL_PROVIDER}/role-aliases/${AWS_ROLE_ALIAS}/credentials" --cacert cacert.pem)
aws_access_key_id=$(jq --raw-output '.credentials.accessKeyId' <<< "${token}")
aws_secret_access_key=$(jq --raw-output '.credentials.secretAccessKey' <<< "${token}")
aws_session_token=$(jq --raw-output '.credentials.sessionToken' <<< "${token}")



# Export additional varaiables needed to run the commands towards AWS
current_time=$(jq --raw-output '.credentials.expiration' <<< "$token")
echo "Temporary credentials created with an expiration date set to:${current_time}"
echo ""
echo "Run the following commands in your shell to export the temporary credentials so that they can be picked up by docker compose:"
echo ""
echo "export AWS_ACCESS_KEY_ID=${aws_access_key_id}"
echo "export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}"
echo "export AWS_SESSION_TOKEN=${aws_session_token}"

