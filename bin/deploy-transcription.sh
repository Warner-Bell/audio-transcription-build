#!/bin/bash

# Constants
STACK_NAME="your-stack-name"    # Input a CloudFormation Stack Name (IT MUST BE ALL LOWERCASE!!!)
TEMPLATE_FILE="./cfn/audio-transcription.yaml" # CloudFormation template file path
TIMESTAMP=$(date +"%Y%m%d%H%M%S")           # Generates a timestamp in the format YYYYMMDDHHMMSS
REGION="us-east-1"                          # Modify to preferred AWS region
PROFILE="default"                           # Adjust for named profile if required

# Bucket names
INPUT_BUCKET_NAME="${STACK_NAME}-${TIMESTAMP}-input"
OUTPUT_BUCKET_NAME="${STACK_NAME}-${TIMESTAMP}-output"
LOG_BUCKET_NAME="${STACK_NAME}-${TIMESTAMP}-logs"
FORMATTED_BUCKET_NAME="${STACK_NAME}-${TIMESTAMP}-formatted"

# Function to check if AWS CLI is installed
check_aws_cli_installed() {
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is not installed. Please install it and try again."
        exit 1
    fi
}

# Function to validate parameters
validate_parameters() {
    if [[ -z "$STACK_NAME" ]]; then
        echo "❌ STACK_NAME is not defined. Please set STACK_NAME and try again."
        exit 1
    fi

    if [[ -z "$REGION" ]]; then
        echo "❌ REGION is not defined. Please set REGION and try again."
        exit 1
    fi

    if [[ -z "$PROFILE" ]]; then
        echo "⚠️ AWS_PROFILE is not set. Using the default profile."
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

    # Notify upon successful completion
    notify_completion
}

# Run the main function
main
