#!/bin/bash

# Script to deploy CloudFormation template

# Constants
STACK_NAME="audio-transcription-stack"
TEMPLATE_FILE="transcribe.yaml"
REGION="us-east-1" # Modify this to your preferred AWS region

# Function to check if AWS CLI is installed
check_aws_cli_installed() {
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is not installed. Please install it and try again."
        exit 1
    fi
}

# Function to deploy CloudFormation stack
deploy_stack() {
    echo "🚀 Deploying CloudFormation stack: $STACK_NAME..."

    aws cloudformation deploy \
        --template-file $TEMPLATE_FILE \
        --stack-name $STACK_NAME \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION

    if [ $? -eq 0 ]; then
        echo "✅ CloudFormation stack '$STACK_NAME' deployed successfully!"
    else
        echo "❌ Failed to deploy CloudFormation stack."
        exit 1
    fi
}

# Main script execution
main() {
    echo "🔍 Checking for AWS CLI installation..."
    check_aws_cli_installed

    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo "❌ Template file '$TEMPLATE_FILE' not found. Please make sure it exists."
        exit 1
    fi

    deploy_stack
}

# Run the main function
main
