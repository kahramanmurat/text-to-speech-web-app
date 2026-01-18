# Quick Deployment Guide

This is a step-by-step checklist for deploying the Text-to-Speech application.

## Prerequisites Checklist

- [ ] AWS Account created
- [ ] AWS CLI installed and configured
- [ ] Node.js installed (for packaging Lambda function)

## Deployment Steps

### 1. S3 Bucket Setup (5 minutes)

- [ ] Create S3 bucket with unique name
- [ ] Note bucket name: `_______________________`
- [ ] Configure CORS using `aws-config/s3-cors-configuration.json`
- [ ] (Optional) Set up lifecycle rule to delete files after 1 day

### 2. IAM Role Setup (5 minutes)

- [ ] Create IAM role: `TextToSpeechLambdaRole`
- [ ] Attach trust policy from `aws-config/iam-trust-policy.json`
- [ ] Create inline policy from `aws-config/iam-role-policy.json`
- [ ] Replace `YOUR-BUCKET-NAME` with your actual bucket name
- [ ] Save the policy

### 3. Lambda Function Setup (10 minutes)

- [ ] Run the following commands:
```bash
cd lambda
npm install
zip -r function.zip .
```
- [ ] Create Lambda function: `TextToSpeechFunction`
- [ ] Runtime: Node.js 18.x
- [ ] Execution role: `TextToSpeechLambdaRole`
- [ ] Upload `function.zip`
- [ ] Add environment variable: `S3_BUCKET_NAME` = your bucket name
- [ ] Set timeout to 30 seconds
- [ ] Set memory to 256 MB (optional, but recommended)

### 4. API Gateway Setup (10 minutes)

- [ ] Create REST API: `TextToSpeechAPI`
- [ ] Create resource: `/text-to-speech`
- [ ] Create POST method with Lambda proxy integration
- [ ] Link to `TextToSpeechFunction`
- [ ] Enable CORS on the resource
- [ ] Deploy API to `prod` stage
- [ ] Copy Invoke URL: `_______________________`

### 5. Frontend Configuration (2 minutes)

- [ ] Open `index.html`
- [ ] Replace `YOUR_API_GATEWAY_URL` with your actual API Gateway URL
- [ ] Save the file

### 6. Testing (5 minutes)

Test with curl:
```bash
curl -X POST https://YOUR_API_URL/prod/text-to-speech \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello, this is a test of the text to speech system.",
    "voiceId": "Joanna",
    "languageCode": "en-US"
  }'
```

Expected response:
```json
{
  "message": "Text successfully converted to speech",
  "audioUrl": "https://...",
  "fileName": "speech-xxx.mp3",
  "voice": "Joanna",
  "language": "en-US",
  "expiresIn": 3600
}
```

- [ ] Curl test successful
- [ ] Open `index.html` in browser
- [ ] Test text-to-speech conversion
- [ ] Verify audio plays correctly
- [ ] Test download functionality

### 7. Deploy Frontend (Choose One)

#### Option A: Local Use
- [ ] Open `index.html` directly in browser

#### Option B: S3 Static Website
- [ ] Create new S3 bucket for website
- [ ] Enable static website hosting
- [ ] Upload `index.html`
- [ ] Configure bucket policy for public access
- [ ] Access via S3 website URL

#### Option C: GitHub Pages
- [ ] Create GitHub repository
- [ ] Push `index.html`
- [ ] Enable GitHub Pages
- [ ] Access via GitHub Pages URL

#### Option D: Netlify/Vercel
- [ ] Create account
- [ ] Deploy `index.html`
- [ ] Access via provided URL

## Configuration Summary

Fill in your deployment details:

```
S3 Bucket Name: _______________________
IAM Role ARN: _______________________
Lambda Function ARN: _______________________
API Gateway URL: _______________________
Frontend URL: _______________________
```

## Verification Checklist

- [ ] Lambda function has correct IAM permissions
- [ ] Lambda function environment variable is set
- [ ] API Gateway is deployed to `prod` stage
- [ ] CORS is enabled on API Gateway
- [ ] S3 CORS configuration is applied
- [ ] Frontend has correct API endpoint URL
- [ ] End-to-end test successful

## Common Issues & Solutions

### Issue: CORS Error in Browser
**Solution**:
1. Verify CORS is enabled in API Gateway
2. Redeploy API to `prod` stage
3. Check S3 CORS configuration

### Issue: 500 Error from API
**Solution**:
1. Check CloudWatch logs for Lambda function
2. Verify S3_BUCKET_NAME environment variable
3. Confirm IAM permissions are correct

### Issue: Audio URL Returns 403
**Solution**:
1. Check S3 bucket permissions
2. Verify Lambda has S3:GetObject permission
3. Ensure presigned URL hasn't expired

### Issue: Lambda Timeout
**Solution**:
1. Increase Lambda timeout to 30+ seconds
2. Increase memory to 256 MB
3. Check for errors in CloudWatch logs

## Post-Deployment

### Monitoring
1. Set up CloudWatch alarms for:
   - Lambda errors
   - API Gateway 4xx/5xx errors
   - Lambda duration

### Optimization
1. Enable CloudWatch Insights
2. Monitor costs in AWS Cost Explorer
3. Set up billing alerts

### Security
1. Consider adding API keys
2. Implement rate limiting
3. Use specific CORS origins instead of "*"
4. Enable AWS WAF for API Gateway (optional)

## Estimated Time
Total deployment time: **30-45 minutes**

## Cost Tracking

Monitor your usage:
- CloudWatch → Metrics → Polly, Lambda, S3
- Billing Dashboard → Cost Explorer
- Set up budget alerts

## Support Resources

- [AWS Polly Documentation](https://docs.aws.amazon.com/polly/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
