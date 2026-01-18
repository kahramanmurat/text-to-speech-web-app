#!/bin/bash

# Text-to-Speech AWS Deployment Script (No IAM Permissions Required)
# This script skips IAM role checks and uses role ARN directly

set -e

echo "=========================================="
echo "Text-to-Speech Application Deployment"
echo "No IAM Permissions Required"
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

# Get AWS region and account ID
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
    echo "Enter AWS region (e.g., us-east-1): "
    read AWS_REGION
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Using AWS region: $AWS_REGION"
echo "AWS Account ID: $ACCOUNT_ID"
echo ""

# Construct role ARN manually
ROLE_NAME="PollyTranslationRole"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

echo "Using IAM Role ARN: $ROLE_ARN"
echo -e "${YELLOW}Note: Make sure this role exists and has the necessary permissions${NC}"
echo ""

# Step 1: Create S3 Bucket
echo "Step 1: Creating S3 Bucket"
echo "Enter a unique name for your S3 bucket (e.g., tts-audio-files-$ACCOUNT_ID): "
read BUCKET_NAME

if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    echo "Creating bucket..."
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

# Step 2: Package Lambda Function
echo "Step 2: Packaging Lambda Function"
cd lambda

if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install --production
fi

echo "Creating deployment package..."
zip -r ../function.zip . > /dev/null
cd ..
echo -e "${GREEN}✓ Lambda function packaged${NC}"
echo ""

# Step 3: Create or Update Lambda Function
echo "Step 3: Creating/Updating Lambda Function"
FUNCTION_NAME="TextToSpeechFunction"

# Try to create the function
echo "Attempting to create Lambda function..."
if aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime nodejs18.x \
    --role "$ROLE_ARN" \
    --handler index.handler \
    --zip-file fileb://function.zip \
    --timeout 30 \
    --memory-size 256 \
    --environment "Variables={S3_BUCKET_NAME=$BUCKET_NAME}" \
    --region "$AWS_REGION" 2>&1 | tee /tmp/lambda-create.log; then
    echo -e "${GREEN}✓ Lambda function created${NC}"
else
    # If creation fails because it exists, update it
    if grep -q "ResourceConflictException" /tmp/lambda-create.log; then
        echo -e "${YELLOW}Function exists, updating...${NC}"

        # Update function code
        aws lambda update-function-code \
            --function-name "$FUNCTION_NAME" \
            --zip-file fileb://function.zip \
            --region "$AWS_REGION" > /dev/null

        echo "Waiting for update to complete..."
        sleep 5

        # Update function configuration
        aws lambda update-function-configuration \
            --function-name "$FUNCTION_NAME" \
            --environment "Variables={S3_BUCKET_NAME=$BUCKET_NAME}" \
            --timeout 30 \
            --memory-size 256 \
            --region "$AWS_REGION" > /dev/null

        echo -e "${GREEN}✓ Lambda function updated${NC}"
    else
        echo -e "${RED}Failed to create Lambda function. Check the error above.${NC}"
        cat /tmp/lambda-create.log
        exit 1
    fi
fi
echo ""

# Clean up
rm -f function.zip /tmp/lambda-create.log

echo "=========================================="
echo -e "${GREEN}Deployment Completed!${NC}"
echo "=========================================="
echo ""
echo "Resources Created:"
echo "  • S3 Bucket: $BUCKET_NAME"
echo "  • Lambda Function: $FUNCTION_NAME"
echo "  • Using Role: $ROLE_NAME"
echo "  • Region: $AWS_REGION"
echo ""
echo -e "${YELLOW}IMPORTANT: Update Role Permissions${NC}"
echo "Your role ($ROLE_NAME) needs these permissions:"
echo "  1. CloudWatch Logs (logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents)"
echo "  2. Amazon Polly (polly:SynthesizeSpeech)"
echo "  3. S3 Access (s3:PutObject, s3:GetObject) for bucket: $BUCKET_NAME"
echo ""
echo "See aws-config/iam-role-policy.json for the full policy (update YOUR-BUCKET-NAME)"
echo ""
echo "=========================================="
echo -e "${YELLOW}Next Steps:${NC}"
echo "=========================================="
echo ""
echo "1. Update your IAM role with necessary permissions (ask your AWS admin if needed)"
echo "2. Set up API Gateway:"
echo "   - Follow: aws-config/api-gateway-setup.md"
echo "3. Update index.html with your API Gateway URL (line 289)"
echo "4. Test your application!"
echo ""
echo -e "${GREEN}Script completed successfully!${NC}"
