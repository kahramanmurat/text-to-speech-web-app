#!/bin/bash

# Text-to-Speech AWS Deployment Script
# This script automates the deployment of the text-to-speech application

set -e

echo "=========================================="
echo "Text-to-Speech Application Deployment"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    echo "Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not configured${NC}"
    echo "Please run: aws configure"
    exit 1
fi

echo -e "${GREEN}✓ AWS CLI is installed and configured${NC}"
echo ""

# Get AWS region
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
    echo "Enter AWS region (e.g., us-east-1): "
    read AWS_REGION
fi
echo "Using AWS region: $AWS_REGION"
echo ""

# Step 1: Create S3 Bucket
echo "Step 1: Creating S3 Bucket"
echo "Enter a unique name for your S3 bucket (e.g., my-tts-audio-files-123): "
read BUCKET_NAME

if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3 mb "s3://$BUCKET_NAME" --region "$AWS_REGION"
    echo -e "${GREEN}✓ S3 bucket created: $BUCKET_NAME${NC}"
else
    echo -e "${YELLOW}Bucket already exists: $BUCKET_NAME${NC}"
fi

# Configure S3 CORS
echo "Configuring S3 CORS..."
aws s3api put-bucket-cors \
    --bucket "$BUCKET_NAME" \
    --cors-configuration file://aws-config/s3-cors-configuration.json
echo -e "${GREEN}✓ S3 CORS configured${NC}"
echo ""

# Step 2: Create IAM Role
echo "Step 2: Creating IAM Role"
ROLE_NAME="TextToSpeechLambdaRole"

# Check if role exists
if aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
    echo -e "${YELLOW}Role already exists: $ROLE_NAME${NC}"
else
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document file://aws-config/iam-trust-policy.json
    echo -e "${GREEN}✓ IAM role created: $ROLE_NAME${NC}"
fi

# Update and attach policy
sed "s/YOUR-BUCKET-NAME/$BUCKET_NAME/g" aws-config/iam-role-policy.json > /tmp/iam-role-policy.json

aws iam put-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name "TextToSpeechPolicy" \
    --policy-document file:///tmp/iam-role-policy.json

echo -e "${GREEN}✓ IAM policy attached${NC}"
echo ""

# Wait for IAM role to propagate
echo "Waiting for IAM role to propagate..."
sleep 10

# Step 3: Create Lambda Function
echo "Step 3: Creating Lambda Function"
FUNCTION_NAME="TextToSpeechFunction"

# Package Lambda function
echo "Packaging Lambda function..."
cd lambda
npm install --production
zip -r ../function.zip . > /dev/null
cd ..
echo -e "${GREEN}✓ Lambda function packaged${NC}"

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)

# Create or update Lambda function
if aws lambda get-function --function-name "$FUNCTION_NAME" &> /dev/null; then
    echo -e "${YELLOW}Lambda function exists, updating...${NC}"
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file fileb://function.zip > /dev/null
else
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --runtime nodejs18.x \
        --role "$ROLE_ARN" \
        --handler index.handler \
        --zip-file fileb://function.zip \
        --timeout 30 \
        --memory-size 256 \
        --environment "Variables={S3_BUCKET_NAME=$BUCKET_NAME}" > /dev/null
    echo -e "${GREEN}✓ Lambda function created${NC}"
fi

# Update environment variables
aws lambda update-function-configuration \
    --function-name "$FUNCTION_NAME" \
    --environment "Variables={S3_BUCKET_NAME=$BUCKET_NAME}" > /dev/null

echo -e "${GREEN}✓ Lambda function configured${NC}"
echo ""

# Clean up
rm -f function.zip /tmp/iam-role-policy.json

# Step 4: API Gateway Setup Instructions
echo "=========================================="
echo -e "${YELLOW}Manual Step Required: API Gateway Setup${NC}"
echo "=========================================="
echo ""
echo "Please complete the following steps in AWS Console:"
echo ""
echo "1. Go to API Gateway console"
echo "2. Create a new REST API named 'TextToSpeechAPI'"
echo "3. Create a resource '/text-to-speech'"
echo "4. Create a POST method with Lambda proxy integration"
echo "5. Link to Lambda function: $FUNCTION_NAME"
echo "6. Enable CORS on the resource"
echo "7. Deploy to 'prod' stage"
echo "8. Copy the Invoke URL"
echo ""
echo "Or follow the detailed guide in: aws-config/api-gateway-setup.md"
echo ""
echo "=========================================="
echo -e "${GREEN}Deployment Summary${NC}"
echo "=========================================="
echo "S3 Bucket: $BUCKET_NAME"
echo "IAM Role: $ROLE_NAME"
echo "Lambda Function: $FUNCTION_NAME"
echo "Region: $AWS_REGION"
echo ""
echo "Next steps:"
echo "1. Complete API Gateway setup (see above)"
echo "2. Update index.html with your API Gateway URL"
echo "3. Deploy index.html to your hosting platform"
echo ""
echo -e "${GREEN}Deployment script completed!${NC}"
