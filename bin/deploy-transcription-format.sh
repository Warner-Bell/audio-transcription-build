#!/bin/bash

# Constants
STACK_NAME="YourStackName"           # CloudFormation Stack Name
TEMPLATE_FILE="./cfn/transcribe.yaml" # CloudFormation template file path
REGION="us-east-1"                   # Modify to preferred AWS region
PROFILE="default"                    # Adjust for named profile if required

# Bucket names
INPUT_BUCKET_NAME="${STACK_NAME}-input"
OUTPUT_BUCKET_NAME="${STACK_NAME}-output"
LOG_BUCKET_NAME="${STACK_NAME}-logs"
FORMATTED_BUCKET_NAME="${STACK_NAME}-formatted"

# Function to check if AWS CLI is installed
check_aws_cli_installed() {
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is not installed. Please install it and try again."
        exit 1
    fi
}

# Function to validate parameters
validate_parameters() {
    if [[ -z "$STACK_NAME" || -z "$REGION" ]]; then
        echo "❌ STACK_NAME or REGION is not defined. Please set and try again."
        exit 1
    fi
}

# Function to check if template file exists
check_template_file_exists() {
    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo "❌ Template file '$TEMPLATE_FILE' not found. Please make sure it exists."
        exit 1
    fi
}

# Deploy CloudFormation stack
deploy_stack() {
    echo "🚀 Deploying CloudFormation stack: $STACK_NAME..."
    
    aws cloudformation deploy \
        --template-file "$TEMPLATE_FILE" \
        --stack-name "$STACK_NAME" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$REGION" \
        --profile "$PROFILE" \
        --parameter-overrides \
            InputBucketName="$INPUT_BUCKET_NAME" \
            OutputBucketName="$OUTPUT_BUCKET_NAME" \
            LogBucketName="$LOG_BUCKET_NAME" \
            FormattedOutputBucketName="$FORMATTED_BUCKET_NAME"

    if [ $? -eq 0 ]; then
        echo "✅ CloudFormation stack '$STACK_NAME' deployed successfully!"
    else
        echo "❌ Failed to deploy CloudFormation stack."
        exit 1
    fi
}

# Set up S3 notifications and IAM permissions for Lambdas
configure_s3_notifications_and_permissions() {
    echo "🔄 Configuring S3 bucket notifications and permissions..."

    # Retrieve Account ID
    ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text --region "$REGION")

    # Retrieve Lambda role for permissions
    LAMBDA_ROLE_ARN=$(aws lambda get-function-configuration --function-name TranscribeAudioFunction --query "Role" --output text --region "$REGION")
    FORMAT_LAMBDA_ROLE_ARN=$(aws lambda get-function-configuration --function-name FormatTranscriptionFunction --query "Role" --output text --region "$REGION")

    # Attach policy for both Lambda roles to access all buckets
    aws iam put-role-policy \
        --role-name $(basename "$LAMBDA_ROLE_ARN") \
        --policy-name "FullLambdaPermissions" \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
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
                    "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
                    "Resource": [
                        "arn:aws:logs:'"$REGION"':'"$ACCOUNT_ID"':log-group:/aws/lambda/TranscribeAudioFunction*",
                        "arn:aws:logs:'"$REGION"':'"$ACCOUNT_ID"':log-group:/aws/lambda/FormatTranscriptionFunction*"
                    ]
                }
            ]
        }'

    if [ $? -eq 0 ]; then
        echo "✅ Successfully updated permissions for both Lambda functions."
    else
        echo "❌ Failed to update Lambda permissions."
        exit 1
    fi

    # Configure S3 notification for input bucket to trigger Transcribe Lambda
    aws s3api put-bucket-notification-configuration \
        --bucket "$INPUT_BUCKET_NAME" \
        --notification-configuration '{
            "LambdaFunctionConfigurations": [
                {
                    "Id": "TranscribeAudioTrigger",
                    "LambdaFunctionArn": "arn:aws:lambda:'"$REGION"':'"$ACCOUNT_ID"':function:TranscribeAudioFunction",
                    "Events": ["s3:ObjectCreated:*"],
                    "Filter": {
                        "Key": {
                            "FilterRules": [
                                {"Name": "suffix", "Value": ".mp4"},
                                {"Name": "suffix", "Value": ".mp3"},
                                {"Name": "suffix", "Value": ".wav"}
                            ]
                        }
                    }
                }
            ]
        }'

    # Configure S3 notification for output bucket to trigger Format Lambda
    aws s3api put-bucket-notification-configuration \
        --bucket "$OUTPUT_BUCKET_NAME" \
        --notification-configuration '{
            "LambdaFunctionConfigurations": [
                {
                    "Id": "FormatTranscriptionTrigger",
                    "LambdaFunctionArn": "arn:aws:lambda:'"$REGION"':'"$ACCOUNT_ID"':function:FormatTranscriptionFunction",
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
        echo "✅ S3 notifications configured successfully."
    else
        echo "❌ Failed to configure S3 notifications."
        exit 1
    fi
}

# Notify upon completion (optional)
notify_completion() {
    if command -v notify-send &> /dev/null; then
        notify-send "CloudFormation Deployment" "Stack $STACK_NAME deployed and configured successfully!" --urgency=normal
    else
        echo "ℹ️ Consider installing 'notify-send' for desktop notifications."
    fi
}

# Main script execution
main() {
    echo "🔍 Checking for AWS CLI installation..."
    check_aws_cli_installed

    echo "🔍 Validating parameters..."
    validate_parameters

    echo "📄 Checking for CloudFormation template file..."
    check_template_file_exists

    # Deploy the stack
    deploy_stack

    # Configure S3 notifications and permissions
    configure_s3_notifications_and_permissions

    # Notify upon successful completion
    notify_completion
}

# Run the main function
main
