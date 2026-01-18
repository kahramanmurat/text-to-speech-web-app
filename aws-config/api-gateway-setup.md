# API Gateway Setup Guide

This guide explains how to set up Amazon API Gateway to connect your frontend to the Lambda function.

## Step 1: Create a REST API

1. Go to the **AWS Console** → **API Gateway**
2. Click **Create API**
3. Choose **REST API** (not private)
4. Click **Build**
5. Configure:
   - **API name**: `TextToSpeechAPI`
   - **Description**: `API for text to speech conversion`
   - **Endpoint Type**: Regional
6. Click **Create API**

## Step 2: Create a Resource

1. In the API Gateway console, select your API
2. Click **Actions** → **Create Resource**
3. Configure:
   - **Resource Name**: `text-to-speech`
   - **Resource Path**: `/text-to-speech`
   - **Enable API Gateway CORS**: ✓ (Check this box)
4. Click **Create Resource**

## Step 3: Create POST Method

1. Select the `/text-to-speech` resource
2. Click **Actions** → **Create Method**
3. Select **POST** from the dropdown
4. Click the checkmark ✓
5. Configure:
   - **Integration type**: Lambda Function
   - **Use Lambda Proxy integration**: ✓ (Check this box)
   - **Lambda Region**: Select your region (e.g., us-east-1)
   - **Lambda Function**: Type your function name (e.g., `TextToSpeechFunction`)
6. Click **Save**
7. Click **OK** to give API Gateway permission to invoke your Lambda

## Step 4: Enable CORS

1. Select the `/text-to-speech` resource
2. Click **Actions** → **Enable CORS**
3. Configure:
   - **Access-Control-Allow-Origin**: `*` (or your specific domain)
   - **Access-Control-Allow-Headers**: `Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token`
   - **Access-Control-Allow-Methods**: Check `POST` and `OPTIONS`
4. Click **Enable CORS and replace existing CORS headers**
5. Click **Yes, replace existing values**

## Step 5: Deploy the API

1. Click **Actions** → **Deploy API**
2. Configure:
   - **Deployment stage**: [New Stage]
   - **Stage name**: `prod`
   - **Stage description**: Production stage
3. Click **Deploy**

## Step 6: Get Your API Endpoint URL

1. After deployment, you'll see the **Invoke URL** at the top
2. It will look like: `https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod`
3. Your full endpoint will be: `https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod/text-to-speech`

## Step 7: Update Your Frontend

1. Open `index.html`
2. Find this line:
   ```javascript
   const API_ENDPOINT = 'https://YOUR_API_GATEWAY_URL/prod/text-to-speech';
   ```
3. Replace with your actual endpoint:
   ```javascript
   const API_ENDPOINT = 'https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod/text-to-speech';
   ```

## Optional: Add API Key (For Production)

If you want to add API key authentication:

1. In API Gateway, go to **API Keys**
2. Click **Actions** → **Create API Key**
3. Give it a name and click **Save**
4. Go to **Usage Plans** → **Create**
5. Link your API and stage
6. Add the API key to the usage plan
7. In your method, enable **API Key Required**
8. Redeploy your API

Then update your frontend to include the API key in headers:
```javascript
headers: {
    'Content-Type': 'application/json',
    'x-api-key': 'your-api-key-here'
}
```

## Testing

You can test your API using curl:

```bash
curl -X POST https://YOUR_API_URL/prod/text-to-speech \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello, this is a test",
    "voiceId": "Joanna",
    "languageCode": "en-US"
  }'
```

## Troubleshooting

- **CORS errors**: Make sure CORS is enabled and the OPTIONS method returns proper headers
- **500 errors**: Check Lambda function logs in CloudWatch
- **403 errors**: Check IAM permissions for Lambda
- **Timeout errors**: Increase Lambda timeout (default is 3 seconds, set to at least 30 seconds)
