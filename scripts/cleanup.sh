#!/bin/bash

# Text-to-Speech AWS Cleanup Script
# This script removes all AWS resources created for the text-to-speech application

set -e

echo "=========================================="
echo "Text-to-Speech Application Cleanup"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}WARNING: This will delete all resources for the text-to-speech application${NC}"
echo "This includes:"
echo "  - Lambda function"
echo "  - IAM role and policies"
echo "  - S3 bucket and all audio files"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled"
    exit 0
fi

# Get resource names
echo ""
echo "Enter the S3 bucket name to delete: "
read BUCKET_NAME

FUNCTION_NAME="TextToSpeechFunction"
ROLE_NAME="TextToSpeechLambdaRole"

# Delete Lambda function
echo ""
echo "Deleting Lambda function..."
if aws lambda get-function --function-name "$FUNCTION_NAME" &> /dev/null; then
    aws lambda delete-function --function-name "$FUNCTION_NAME"
    echo -e "${GREEN}✓ Lambda function deleted${NC}"
else
    echo -e "${YELLOW}Lambda function not found${NC}"
fi

# Delete IAM role
echo "Deleting IAM role..."
if aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
    # Delete inline policies
    POLICIES=$(aws iam list-role-policies --role-name "$ROLE_NAME" --query 'PolicyNames' --output text)
    for POLICY in $POLICIES; do
        aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY"
    done

    # Delete role
    aws iam delete-role --role-name "$ROLE_NAME"
    echo -e "${GREEN}✓ IAM role deleted${NC}"
else
    echo -e "${YELLOW}IAM role not found${NC}"
fi

# Empty and delete S3 bucket
echo "Deleting S3 bucket..."
if aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
    echo "Emptying bucket..."
    aws s3 rm "s3://$BUCKET_NAME" --recursive

    echo "Deleting bucket..."
    aws s3 rb "s3://$BUCKET_NAME"
    echo -e "${GREEN}✓ S3 bucket deleted${NC}"
else
    echo -e "${YELLOW}S3 bucket not found${NC}"
fi

# Delete CloudWatch log groups
echo "Deleting CloudWatch log groups..."
LOG_GROUP="/aws/lambda/$FUNCTION_NAME"
if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" &> /dev/null; then
    aws logs delete-log-group --log-group-name "$LOG_GROUP" 2> /dev/null || true
    echo -e "${GREEN}✓ CloudWatch log groups deleted${NC}"
else
    echo -e "${YELLOW}CloudWatch log groups not found${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Cleanup completed!${NC}"
echo "=========================================="
echo ""
echo "Note: You must manually delete the API Gateway API:"
echo "1. Go to API Gateway console"
echo "2. Select 'TextToSpeechAPI'"
echo "3. Click Actions → Delete"
echo ""
echo "All other resources have been removed."
