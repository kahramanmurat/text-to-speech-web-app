# Quick Start Guide

Get your Text-to-Speech application running in 15 minutes!

## Prerequisites

- AWS Account
- AWS CLI installed: `aws --version`
- AWS CLI configured: `aws configure`

## Option 1: Automated Deployment (Recommended)

```bash
# Navigate to project directory
cd text-to-speech

# Run deployment script
./scripts/deploy.sh

# Follow the prompts to:
# 1. Enter S3 bucket name
# 2. Wait for resources to be created
```

Then manually:
1. Create API Gateway (5 minutes) - Follow `aws-config/api-gateway-setup.md`
2. Update `index.html` with your API Gateway URL
3. Open `index.html` in your browser

## Option 2: Manual Deployment

### Step 1: Create S3 Bucket (2 min)
```bash
BUCKET_NAME="my-tts-audio-files-$(date +%s)"
aws s3 mb "s3://$BUCKET_NAME"
aws s3api put-bucket-cors \
    --bucket "$BUCKET_NAME" \
    --cors-configuration file://aws-config/s3-cors-configuration.json
```

### Step 2: Create IAM Role (3 min)
```bash
# Create role
aws iam create-role \
    --role-name TextToSpeechLambdaRole \
    --assume-role-policy-document file://aws-config/iam-trust-policy.json

# Update policy with bucket name
sed "s/YOUR-BUCKET-NAME/$BUCKET_NAME/g" \
    aws-config/iam-role-policy.json > /tmp/policy.json

# Attach policy
aws iam put-role-policy \
    --role-name TextToSpeechLambdaRole \
    --policy-name TextToSpeechPolicy \
    --policy-document file:///tmp/policy.json
```

### Step 3: Create Lambda Function (5 min)
```bash
# Package function
cd lambda && npm install && zip -r ../function.zip . && cd ..

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name TextToSpeechLambdaRole \
    --query 'Role.Arn' --output text)

# Create function
aws lambda create-function \
    --function-name TextToSpeechFunction \
    --runtime nodejs18.x \
    --role "$ROLE_ARN" \
    --handler index.handler \
    --zip-file fileb://function.zip \
    --timeout 30 \
    --memory-size 256 \
    --environment "Variables={S3_BUCKET_NAME=$BUCKET_NAME}"
```

### Step 4: Create API Gateway (5 min)
Follow the guide: `aws-config/api-gateway-setup.md`

### Step 5: Configure Frontend (1 min)
1. Open `index.html`
2. Replace `YOUR_API_GATEWAY_URL` with your API Gateway URL
3. Save the file

### Step 6: Test (2 min)
```bash
# Test API
./test/test-api.sh https://YOUR-API-URL/prod/text-to-speech

# Or open index.html in browser
open index.html  # macOS
# or just double-click index.html
```

## Testing Your Deployment

### Test 1: API Test
```bash
curl -X POST https://YOUR-API-URL/prod/text-to-speech \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello World",
    "voiceId": "Joanna",
    "languageCode": "en-US"
  }'
```

Expected response:
```json
{
  "message": "Text successfully converted to speech",
  "audioUrl": "https://...",
  "fileName": "speech-xxx.mp3"
}
```

### Test 2: Browser Test
1. Open `index.html`
2. Enter text: "Hello, this is a test"
3. Click "Convert to Speech"
4. Audio should play automatically

## Common Commands

### View Lambda Logs
```bash
aws logs tail /aws/lambda/TextToSpeechFunction --follow
```

### List Audio Files in S3
```bash
aws s3 ls s3://YOUR-BUCKET-NAME/
```

### Update Lambda Code
```bash
cd lambda
zip -r ../function.zip .
aws lambda update-function-code \
    --function-name TextToSpeechFunction \
    --zip-file fileb://function.zip
cd ..
```

### Delete Everything
```bash
./scripts/cleanup.sh
```

## Troubleshooting

### "AccessDenied" errors
```bash
# Check IAM policy is attached
aws iam list-role-policies --role-name TextToSpeechLambdaRole
```

### "CORS" errors in browser
```bash
# Check S3 CORS
aws s3api get-bucket-cors --bucket YOUR-BUCKET-NAME

# Redeploy API Gateway
# Go to API Gateway console → Actions → Deploy API
```

### Lambda timeout
```bash
# Increase timeout
aws lambda update-function-configuration \
    --function-name TextToSpeechFunction \
    --timeout 60
```

## What's Next?

### Deploy Frontend
- **GitHub Pages**: Push `index.html` to GitHub repo
- **Netlify**: Drag and drop `index.html`
- **S3 Website**: Upload to S3 bucket with static hosting
- **Vercel**: Deploy with `vercel` command

### Add Features
- API key authentication
- Rate limiting
- Custom domain
- Analytics
- More voice options

### Monitor Usage
- CloudWatch Dashboard
- Cost Explorer
- Set billing alerts

## Resources

- Full documentation: `README.md`
- Deployment checklist: `DEPLOYMENT.md`
- API Gateway setup: `aws-config/api-gateway-setup.md`

## Support

Issues? Check:
1. CloudWatch Logs
2. API Gateway execution logs
3. S3 bucket permissions
4. IAM role permissions

## Cost Estimate

With AWS Free Tier: **$0/month** for moderate use

After Free Tier:
- ~$0.10 per month for 10,000 conversions
- See `README.md` for detailed cost breakdown
