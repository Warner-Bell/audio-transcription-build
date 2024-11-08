#!/bin/bash

# Define AWS region
REGION="us-east-1"

# Retrieve a bucket name that matches the pattern
bucket_name=$(aws s3api list-buckets --query "Buckets[?contains(Name, '-input') || contains(Name, '-output') || contains(Name, '-formatted') || contains(Name, '-logs')].[Name]" --output text | head -n 1)

# Check if a matching bucket name was found
if [ -z "$bucket_name" ]; then
  echo "❌ No bucket found with the expected naming pattern. Exiting."
  exit 1
fi

echo "✅ Found bucket: $bucket_name"

# Extract the base stack name by removing the suffix and timestamp
# This command removes the timestamp and suffix (e.g., '-input', '-output', '-formatted', '-logs')
STACK_NAME=$(echo "$bucket_name" | sed -E 's/-[0-9]{14}-(input|output|formatted|logs)$//')

# Validate that STACK_NAME was derived correctly
if [ -z "$STACK_NAME" ]; then
  echo "❌ Failed to derive the stack name. Exiting."
  exit 1
fi

echo "✅ Derived Stack Name: $STACK_NAME"

# Retrieve bucket names based on the derived stack name
echo "Retrieving S3 bucket names based on derived stack name '${STACK_NAME}'..."

INPUT_BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${STACK_NAME}-') && ends_with(Name, '-input')].Name | [0]" --output text)
OUTPUT_BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${STACK_NAME}-') && ends_with(Name, '-output')].Name | [0]" --output text)
FORMATTED_BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${STACK_NAME}-') && ends_with(Name, '-formatted')].Name | [0]" --output text)
LOG_BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${STACK_NAME}-') && ends_with(Name, '-logs')].Name | [0]" --output text)

# Check if bucket names were retrieved successfully
if [ "$INPUT_BUCKET_NAME" == "None" ] || [ "$OUTPUT_BUCKET_NAME" == "None" ] || [ "$FORMATTED_BUCKET_NAME" == "None" ] || [ "$LOG_BUCKET_NAME" == "None" ]; then
  echo "❌ Failed to retrieve one or more bucket names. Check if the buckets exist with the specified naming pattern."
  exit 1
fi

# Display retrieved bucket names
echo "✅ Retrieved S3 bucket names:"
echo "INPUT_BUCKET_NAME: $INPUT_BUCKET_NAME"
echo "OUTPUT_BUCKET_NAME: $OUTPUT_BUCKET_NAME"
echo "FORMATTED_BUCKET_NAME: $FORMATTED_BUCKET_NAME"
echo "LOG_BUCKET_NAME: $LOG_BUCKET_NAME"

# Function to empty a given bucket
empty_bucket() {
  local bucket_name=$1
  echo "Emptying bucket: $bucket_name..."

  # Use AWS CLI v2 to delete all objects (including versioned objects) in the bucket
  aws s3 rm "s3://$bucket_name" --recursive --region "$REGION"
  
  if [ $? -eq 0 ]; then
    echo "✅ Successfully emptied bucket: $bucket_name"
  else
    echo "❌ Failed to empty bucket: $bucket_name"
    exit 1
  fi
}

# Empty all objects in each bucket, exiting on error
empty_bucket "$INPUT_BUCKET_NAME" || exit 1
empty_bucket "$OUTPUT_BUCKET_NAME" || exit 1
empty_bucket "$FORMATTED_BUCKET_NAME" || exit 1
empty_bucket "$LOG_BUCKET_NAME" || exit 1

echo "🎉 All specified buckets have been emptied!"
