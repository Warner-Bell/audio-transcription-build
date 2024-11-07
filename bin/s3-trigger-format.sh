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

# Define variables based on retrieved stack name
INPUT_BUCKET_NAME="${STACK_NAME}-input"          # S3 Bucket for input files
OUTPUT_BUCKET_NAME="${STACK_NAME}-output"        # S3 Bucket for transcription output files
FORMATTED_BUCKET_NAME="${STACK_NAME}-formatted"  # S3 Bucket for formatted Word documents
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
