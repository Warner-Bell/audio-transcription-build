#!/bin/bash

# Variables
FOLDER_PATH="/workspace/audio-transcription-build/audio-samples/"  # Local folder path to upload (e.g., "/path/to/folder/")
AWS_REGION="us-east-1"                                             # AWS region (e.g., "us-east-1")
S3_PREFIX=""                                                       # S3 prefix for the folder in the bucket (optional)

# Step 1: Retrieve the latest CloudFormation stack name
echo "Retrieving the first created CloudFormation stack name..."

STACK_NAME=$(aws cloudformation describe-stacks \
  --query "Stacks | sort_by(@, &CreationTime) | [-1].StackName" \
  --output text \
  --region "$AWS_REGION")

if [ -z "$STACK_NAME" ]; then
  echo "❌ No CloudFormation stack found. Exiting."
  exit 1
fi

echo "✅ Retrieved Stack Name: $STACK_NAME"

# Retrieve the latest bucket names based on the base stack name
echo "Retrieving S3 bucket names with base name pattern '${STACK_NAME}'..."

INPUT_BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${STACK_NAME}-') && ends_with(Name, '-input')].Name | [0]" --output text)

# Check if the bucket name was retrieved
if [ "$INPUT_BUCKET_NAME" == "None" ]; then
  echo "❌ Failed to retrieve the input bucket name. Check if the bucket exists with the specified naming pattern."
  exit 1
fi

# Display retrieved bucket name
echo "✅ Retrieved S3 bucket name: $INPUT_BUCKET_NAME"

# Check if FOLDER_PATH and INPUT_BUCKET_NAME are provided
if [ -z "$FOLDER_PATH" ] || [ -z "$INPUT_BUCKET_NAME" ]; then
    echo "❌ FOLDER_PATH and INPUT_BUCKET_NAME are required. Please set these variables and try again."
    exit 1
fi

# Upload all files in the specified folder to the S3 bucket
echo "🚀 Uploading contents of $FOLDER_PATH to s3://$INPUT_BUCKET_NAME/$S3_PREFIX in region $AWS_REGION..."

aws s3 cp "$FOLDER_PATH" "s3://$INPUT_BUCKET_NAME/$S3_PREFIX" --recursive --region "$AWS_REGION"

# Check if the upload was successful
if [ $? -eq 0 ]; then
    echo "✅ Successfully uploaded contents of $FOLDER_PATH to s3://$INPUT_BUCKET_NAME/$S3_PREFIX"
else
    echo "❌ Failed to upload contents of $FOLDER_PATH to S3."
    exit 1
fi
