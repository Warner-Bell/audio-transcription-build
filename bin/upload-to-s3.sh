#!/bin/bash

# Variables
FILE_PATH="/workspace/audio-transcription-build/audio-samples/sample.wav"            # Local file path (e.g., "/path/to/file.txt")
AWS_REGION="us-east-1"   # AWS region (e.g., "us-east-1")
S3_KEY=""                # S3 key (optional - if left empty, the original file name will be used)

# Step 1: Retrieve the latest CloudFormation stack name
echo "Retrieving the first created CloudFormation stack name..."

STACK_NAME=$(aws cloudformation describe-stacks \
  --query "Stacks | sort_by(@, &CreationTime) | [-2].StackName" \
  --output text \
  --region "$AWS_REGION")

if [ -z "$STACK_NAME" ]; then
  echo "❌ No CloudFormation stack found. Exiting."
  exit 1
fi

echo "✅ Retrieved Stack Name: $STACK_NAME"

# Define variables based on retrieved stack name
BUCKET_NAME="${STACK_NAME}-input"         # S3 Bucket for input files

# Check if FILE_PATH and BUCKET_NAME are provided
if [ -z "$FILE_PATH" ] || [ -z "$BUCKET_NAME" ]; then
    echo "❌ FILE_PATH and BUCKET_NAME are required. Please set these variables and try again."
    exit 1
fi

# Set S3_KEY to the original file name if not provided
if [ -z "$S3_KEY" ]; then
    S3_KEY=$(basename "$FILE_PATH")
fi

# Upload file to S3
echo "🚀 Uploading $FILE_PATH to s3://$BUCKET_NAME/$S3_KEY in region $AWS_REGION..."

aws s3 cp "$FILE_PATH" "s3://$BUCKET_NAME/$S3_KEY" --region "$AWS_REGION"

# Check if the upload was successful
if [ $? -eq 0 ]; then
    echo "✅ Successfully uploaded $FILE_PATH to s3://$BUCKET_NAME/$S3_KEY"
else
    echo "❌ Failed to upload $FILE_PATH to S3."
    exit 1
fi
