#!/bin/bash

# Define your region
AWS_REGION="us-east-1"

# Step 1: Retrieve the latest CloudFormation stack name
echo "Retrieving the latest created CloudFormation stack name..."

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
OUTPUT_BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${STACK_NAME}-') && ends_with(Name, '-output')].Name | [0]" --output text)
FORMATTED_BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${STACK_NAME}-') && ends_with(Name, '-formatted')].Name | [0]" --output text)
LOG_BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '${STACK_NAME}-') && ends_with(Name, '-logs')].Name | [0]" --output text)

# Check if bucket names were retrieved
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

LAMBDA_FUNCTION_NAME="TranscribeAudioFunction"   # Name of the Transcription Lambda function
FORMAT_LAMBDA_NAME="FormatTranscriptionFunction" # Name of the Formatting Lambda function

# Step 2: Get the AWS Account ID dynamically
echo "Retrieving AWS Account ID..."

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text --region "$AWS_REGION")

if [ $? -ne 0 ]; then
    echo "❌ Failed to retrieve AWS Account ID. Exiting."
    exit 1
fi

echo "✅ Retrieved AWS Account ID: $ACCOUNT_ID"

# Step 3: Get the Lambda execution role dynamically
echo "Retrieving the execution role for Lambda functions..."

ROLE_ARN=$(aws lambda get-function-configuration \
  --function-name "$LAMBDA_FUNCTION_NAME" \
  --query "Role" \
  --output text \
  --region "$AWS_REGION")

if [ $? -ne 0 ]; then
    echo "❌ Failed to retrieve Lambda execution role. Exiting."
    exit 1
fi

# Extract the role name from the ARN
ROLE_NAME=$(basename "$ROLE_ARN")
echo "✅ Retrieved Lambda execution role: $ROLE_NAME"

# Attach a bucket policy to the logs bucket to allow access logging from input and output buckets
echo "Attaching bucket policy to $LOG_BUCKET_NAME to allow access logging..."

aws s3api put-bucket-policy \
  --bucket "$LOG_BUCKET_NAME" \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::'"$LOG_BUCKET_NAME"'/transcribe-access-logs/*",
        "Condition": {
          "StringEquals": {
            "aws:SourceAccount": "'"$ACCOUNT_ID"'"
          }
        }
      }
    ]
  }'

if [ $? -eq 0 ]; then
    echo "✅ Successfully attached bucket policy to $LOG_BUCKET_NAME."
else
    echo "❌ Failed to attach bucket policy to $LOG_BUCKET_NAME. Exiting."
    exit 1
fi

# Step 4: Attach CloudWatch Logs permissions to Lambda execution role
echo "Attaching CloudWatch Logs permissions to the Lambda execution role $ROLE_NAME..."

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "CloudWatchLogsPermissions" \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": [
          "arn:aws:logs:'"$AWS_REGION"':'"$ACCOUNT_ID"':log-group:/aws/lambda/'"$LAMBDA_FUNCTION_NAME"'*"
        ]
      }
    ]
  }'

if [ $? -eq 0 ]; then
    echo "✅ Successfully attached CloudWatch Logs permissions to Lambda execution role."
else
    echo "❌ Failed to attach CloudWatch Logs permissions. Exiting."
    exit 1
fi

# Step 4: Attach permissions for the formatted output bucket to the Lambda execution role
echo "Attaching permissions for input, output, and formatted buckets to Lambda execution role $ROLE_NAME..."

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "FullLambdaPermissions" \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Resource": [
          "arn:aws:s3:::'"$INPUT_BUCKET_NAME"'",
          "arn:aws:s3:::'"$INPUT_BUCKET_NAME"'/*",
          "arn:aws:s3:::'"$OUTPUT_BUCKET_NAME"'",
          "arn:aws:s3:::'"$OUTPUT_BUCKET_NAME"'/*",
          "arn:aws:s3:::'"$FORMATTED_BUCKET_NAME"'",
          "arn:aws:s3:::'"$FORMATTED_BUCKET_NAME"'/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": [
          "arn:aws:logs:'"$AWS_REGION"':'"$ACCOUNT_ID"':log-group:/aws/lambda/'"$LAMBDA_FUNCTION_NAME"'*",
          "arn:aws:logs:'"$AWS_REGION"':'"$ACCOUNT_ID"':log-group:/aws/lambda/'"$FORMAT_LAMBDA_NAME"'*"
        ]
      }
    ]
  }'

if [ $? -eq 0 ]; then
    echo "✅ Successfully attached permissions for input, output, and formatted output buckets."
else
    echo "❌ Failed to attach permissions. Exiting."
    exit 1
fi

# Step 5: Add permission for S3 to invoke the Transcription Lambda function
echo "Adding permission for S3 to invoke Transcription Lambda function..."

aws lambda add-permission \
  --function-name "$LAMBDA_FUNCTION_NAME" \
  --principal s3.amazonaws.com \
  --statement-id AllowS3InvokeTranscribeLambda \
  --action "lambda:InvokeFunction" \
  --source-arn "arn:aws:s3:::$INPUT_BUCKET_NAME" \
  --source-account "$ACCOUNT_ID" \
  --region "$AWS_REGION"

# Add permission for S3 to invoke the Formatting Lambda function
echo "Adding permission for S3 to invoke Formatting Lambda function..."

aws lambda add-permission \
  --function-name "$FORMAT_LAMBDA_NAME" \
  --principal s3.amazonaws.com \
  --statement-id AllowS3InvokeFormatLambda \
  --action "lambda:InvokeFunction" \
  --source-arn "arn:aws:s3:::$OUTPUT_BUCKET_NAME" \
  --source-account "$ACCOUNT_ID" \
  --region "$AWS_REGION"

# Step 6: Configure S3 bucket notification for the input bucket to trigger the transcription Lambda
echo "Configuring S3 bucket notification for bucket $INPUT_BUCKET_NAME to trigger Lambda function $LAMBDA_FUNCTION_NAME on audio file creation..."

aws s3api put-bucket-notification-configuration \
  --bucket "$INPUT_BUCKET_NAME" \
  --notification-configuration '{
    "LambdaFunctionConfigurations": [
      {
        "Id": "TranscribeAudioTriggerMP4",
        "LambdaFunctionArn": "arn:aws:lambda:'"$AWS_REGION"':'"$ACCOUNT_ID"':function:'"$LAMBDA_FUNCTION_NAME"'",
        "Events": ["s3:ObjectCreated:*"],
        "Filter": {
          "Key": {
            "FilterRules": [
              {"Name": "suffix", "Value": ".mp4"}
            ]
          }
        }
      },
      {
        "Id": "TranscribeAudioTriggerMP3",
        "LambdaFunctionArn": "arn:aws:lambda:'"$AWS_REGION"':'"$ACCOUNT_ID"':function:'"$LAMBDA_FUNCTION_NAME"'",
        "Events": ["s3:ObjectCreated:*"],
        "Filter": {
          "Key": {
            "FilterRules": [
              {"Name": "suffix", "Value": ".mp3"}
            ]
          }
        }
      },
      {
        "Id": "TranscribeAudioTriggerWAV",
        "LambdaFunctionArn": "arn:aws:lambda:'"$AWS_REGION"':'"$ACCOUNT_ID"':function:'"$LAMBDA_FUNCTION_NAME"'",
        "Events": ["s3:ObjectCreated:*"],
        "Filter": {
          "Key": {
            "FilterRules": [
              {"Name": "suffix", "Value": ".wav"}
            ]
          }
        }
      }
    ]
  }'

if [ $? -eq 0 ]; then
    echo "✅ Successfully configured S3 bucket notifications to trigger Transcription Lambda function."
else
    echo "❌ Failed to configure S3 bucket notification for transcription Lambda. Exiting."
    exit 1
fi

# Step 7: Configure S3 bucket notification for the output bucket to trigger the Formatting Lambda
echo "Configuring S3 bucket notification for bucket $OUTPUT_BUCKET_NAME to trigger Lambda function $FORMAT_LAMBDA_NAME on JSON file creation..."

aws s3api put-bucket-notification-configuration \
  --bucket "$OUTPUT_BUCKET_NAME" \
  --notification-configuration '{
    "LambdaFunctionConfigurations": [
      {
        "Id": "FormatTranscriptionTrigger",
        "LambdaFunctionArn": "arn:aws:lambda:'"$AWS_REGION"':'"$ACCOUNT_ID"':function:'"$FORMAT_LAMBDA_NAME"'",
        "Events": ["s3:ObjectCreated:*"],
        "Filter": {
          "Key": {
            "FilterRules": [
              {"Name": "suffix", "Value": ".json"}
            ]
          }
        }
      }
    ]
  }'

if [ $? -eq 0 ]; then
    echo "✅ Successfully configured S3 bucket notification to trigger the Formatting Lambda function."
else
    echo "❌ Failed to configure S3 bucket notification for formatting Lambda. Exiting."
    exit 1
fi

echo "🎉 All actions completed successfully!"
