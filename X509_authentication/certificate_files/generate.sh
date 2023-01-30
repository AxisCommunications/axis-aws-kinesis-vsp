#!/bin/bash

ENV_FILE_PATH="$1"

# Export env vars
set -o allexport
# shellcheck source=/dev/null
source "$ENV_FILE_PATH"
set +o allexport

#Create a temporary directory for generated files
mkdir tmp

echo "Creating IoT Thing: ${AWS_THING} and Thing Type: ${AWS_THING_TYPE}"
aws --profile default iot create-thing-type --thing-type-name "${AWS_THING_TYPE}" > tmp/iot-thing-type.json
aws --profile default iot create-thing --thing-name "${AWS_THING}" --thing-type-name "${AWS_THING_TYPE}" > tmp/iot-thing.json


cat > tmp/iam-policy-document.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "credentials.iot.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF


echo "Creating IAM Role: ${AWS_ROLE}"
if aws --profile default iam get-role --role-name "${AWS_ROLE}" > tmp/iam-role.json ; then
    echo "Role: ${AWS_ROLE} already available, continuing..."
else
    aws --profile default iam create-role --role-name "${AWS_ROLE}" --assume-role-policy-document 'file://tmp/iam-policy-document.json' > tmp/iam-role.json
fi


cat > tmp/iam-permission-document.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "kinesisvideo:DescribeStream",
                "kinesisvideo:PutMedia",
                "kinesisvideo:TagStream",
                "kinesisvideo:GetDataEndpoint"
            ],
            "Resource": "arn:aws:kinesisvideo:*:*:stream/\${credentials-iot:ThingName}/*"
        }
    ]
}
EOF

echo "Attaching permissions policy: ${AWS_IAM_POLICY} to: ${AWS_ROLE}"
aws --profile default iam put-role-policy --role-name "${AWS_ROLE}" --policy-name "${AWS_IAM_POLICY}" --policy-document 'file://tmp/iam-permission-document.json' 

# Create a Role Alias
echo "Creating Role Alias: ${AWS_ROLE_ALIAS}"
if aws --profile default iot describe-role-alias --role-alias "${AWS_ROLE_ALIAS}" > tmp/iot-role-alias.json; then
    echo "Role Alias: ${AWS_ROLE_ALIAS} already available, continuing..."
else
    aws --profile default iot create-role-alias --role-alias "${AWS_ROLE_ALIAS}" --role-arn "$(jq --raw-output '.Role.Arn' tmp/iam-role.json)" --credential-duration-seconds 3600
    aws --profile default iot describe-role-alias --role-alias "${AWS_ROLE_ALIAS}" > tmp/iot-role-alias.json
fi


cat > tmp/iot-policy-document.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iot:Connect"
      ],
      "Resource": "$(jq --raw-output '.roleAliasDescription.roleAliasArn' tmp/iot-role-alias.json)"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iot:AssumeRoleWithCertificate"
      ],
      "Resource": "$(jq --raw-output '.roleAliasDescription.roleAliasArn' tmp/iot-role-alias.json)"
    }
  ]
}
EOF

echo "Creating Policy: ${AWS_IOT_POLICY} that will enable IoT to assume role with the certificate (once it is attached) using the role alias"
if aws --profile default iot get-policy --policy-name "${AWS_IOT_POLICY}"; then
    echo "Policy: ${AWS_IOT_POLICY} already available, continuing..."
else
    aws --profile default iot create-policy --policy-name "${AWS_IOT_POLICY}" --policy-document 'file://tmp/iot-policy-document.json'
fi

echo "Creating the certificate to which the policy for IoT created above must be attached"
aws --profile default iot create-keys-and-certificate --set-as-active --certificate-pem-outfile certificate.pem --public-key-outfile public.pem.key --private-key-outfile private.pem.key > certificate

echo "Attaching the policy for IoT (${AWS_IOT_POLICY} created in earlier steps) to the certificate"
aws --profile default iot attach-policy --policy-name "${AWS_IOT_POLICY}" --target "$(jq --raw-output '.certificateArn' certificate)"

echo "Attaching the IoT thing ${AWS_THING} to the certificate"
aws --profile default  iot attach-thing-principal --thing-name "${AWS_THING}" --principal "$(jq --raw-output '.certificateArn' certificate)"

echo "Getting endpoint needed to authorize requests through the IoT credentials provider"
aws --profile default iot describe-endpoint --endpoint-type iot:CredentialProvider --output text > tmp/iot-credential-provider.txt

echo "Fetching CA certificate needed to establish trust with the back-end service"
curl --silent "${AWS_ROOT_CA_ADDRESS}" --output cacert.pem

# Clean up tmp folder
rm -rf tmp

