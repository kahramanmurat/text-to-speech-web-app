# Text-to-Speech Web Application

> A professional serverless text-to-speech application powered by Amazon Polly, AWS Lambda, and S3

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![AWS](https://img.shields.io/badge/AWS-Lambda%20%7C%20Polly%20%7C%20S3-orange.svg)
![Node.js](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen.svg)

## 🎯 Overview

Convert any text into natural-sounding speech with multiple voice options and language support. This serverless application leverages AWS services for scalability, reliability, and cost-effectiveness.

**Live Demo**: [Your Demo URL]

## ✨ Features

- 🎙️ **13+ Voice Options** - Male, female, and child voices with various accents
- 🌍 **Multi-Language Support** - 11+ languages including English, Spanish, French, German, Japanese
- 🎵 **High-Quality Audio** - Neural and standard voice engines via Amazon Polly
- 💾 **Download Capability** - Save generated audio as MP3 files
- 🎨 **Modern UI** - Clean, responsive interface with real-time character counter
- ⚡ **Serverless** - Scalable and cost-effective architecture
- 🔒 **Secure** - IAM-based permissions and CORS protection

## 🏗️ Architecture

```
┌─────────────────┐
│   Web Browser   │
│   (Frontend)    │
└────────┬────────┘
         │
         │ HTTPS/REST
         ▼
┌─────────────────┐
│  API Gateway    │ ← REST API with CORS
└────────┬────────┘
         │
         │ Lambda Proxy
         ▼
┌─────────────────┐
│  AWS Lambda     │ ← Node.js 18
│  (Processing)   │    • Text validation
└────────┬────────┘    • Polly integration
         │             • S3 upload
         ▼
┌─────────────────┐
│  Amazon Polly   │ ← Text-to-Speech Engine
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Amazon S3     │ ← Audio Storage
└────────┬────────┘    • Public URLs
         │
         ▼
┌─────────────────┐
│   Web Browser   │ ← Audio Playback
└─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- AWS Account
- AWS CLI configured
- Node.js 18.x or higher
- Basic AWS knowledge

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/text-to-speech.git
cd text-to-speech
```

2. **Deploy to AWS**
```bash
chmod +x scripts/deploy-no-iam.sh
./scripts/deploy-no-iam.sh
```

3. **Configure API Gateway** (see [aws-config/api-gateway-setup.md](aws-config/api-gateway-setup.md))

4. **Update frontend**
```javascript
// Edit index.html line 289
const API_ENDPOINT = 'https://YOUR-API-ID.execute-api.REGION.amazonaws.com/prod/text-to-speech';
```

5. **Test locally**
```bash
python3 -m http.server 8000
# Open http://localhost:8000
```

## 📖 Usage

1. Enter text (up to 3000 characters)
2. Select voice and language
3. Click "Convert to Speech"
4. Listen or download the MP3 file

## 🎤 Available Voices

| Voice | Gender | Accent | Language Code |
|-------|--------|--------|---------------|
| Joanna | Female | US | en-US |
| Matthew | Male | US | en-US |
| Amy | Female | British | en-GB |
| Brian | Male | British | en-GB |
| Raveena | Female | Indian | en-IN |
| Emma | Female | British | en-GB |
| Salli | Female | US | en-US |
| Joey | Male | US | en-US |
| Ivy | Female (Child) | US | en-US |

[See all voices](https://docs.aws.amazon.com/polly/latest/dg/voicelist.html)

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| Frontend | HTML5, CSS3, Vanilla JavaScript |
| Backend | AWS Lambda (Node.js 18.x) |
| Text-to-Speech | Amazon Polly |
| Storage | Amazon S3 |
| API | Amazon API Gateway (REST) |
| Authentication | AWS IAM |
| SDK | AWS SDK for JavaScript v3 |

## 📁 Project Structure

```
text-to-speech/
├── index.html                      # Frontend application
├── README.md                       # Documentation
├── DEPLOYMENT.md                   # Deployment guide
├── lambda/
│   ├── index.js                    # Lambda function
│   └── package.json                # Dependencies
├── aws-config/
│   ├── iam-role-policy.json       # IAM permissions
│   ├── s3-cors-configuration.json # S3 CORS
│   └── api-gateway-setup.md       # API Gateway guide
├── scripts/
│   ├── deploy-no-iam.sh           # Deployment script
│   └── cleanup.sh                  # Cleanup script
└── test/
    └── test-api.sh                 # API tests
```

## 💰 Cost Estimate

### AWS Free Tier
- Polly: 5M characters/month (12 months)
- Lambda: 1M requests/month (always free)
- S3: 5GB storage (12 months)
- API Gateway: 1M requests/month (12 months)

### After Free Tier
For 10,000 conversions/month (~100 chars avg):
- Polly (Neural): ~$0.16
- Lambda: ~$0.002
- S3: ~$0.01
- API Gateway: ~$0.035

**Total: ~$0.21/month** 💸

## 🧪 Testing

```bash
# Test API
./test/test-api.sh https://YOUR-API-URL/prod/text-to-speech

# Manual test
curl -X POST https://YOUR-API-URL/prod/text-to-speech \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello","voiceId":"Joanna","languageCode":"en-US"}'
```

## 🚢 Deployment Options

### GitHub Pages
```bash
git add .
git commit -m "Deploy to GitHub Pages"
git push origin main
```
Enable in Settings → Pages

### Netlify
1. Connect GitHub repository
2. Auto-deploy on push

### S3 Static Website
```bash
aws s3 mb s3://your-website
aws s3 website s3://your-website --index-document index.html
aws s3 cp index.html s3://your-website/
```

## 🔒 Security

- ✅ IAM roles with least privilege
- ✅ CORS properly configured
- ✅ Input validation (3000 char limit)
- ✅ CloudWatch logging
- ⚠️ Add API key for production
- ⚠️ Implement rate limiting
- ⚠️ Set S3 lifecycle rules

## �� Troubleshooting

| Issue | Solution |
|-------|----------|
| CORS errors | Enable CORS in API Gateway, redeploy |
| 403 on audio | Check S3 bucket policy |
| Lambda timeout | Increase to 30+ seconds |
| Audio not playing | Check browser console, verify S3 CORS |

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed troubleshooting.

## 🧹 Cleanup

```bash
./scripts/cleanup.sh
```

Manually delete:
- API Gateway API
- Lambda function
- S3 bucket
- IAM role

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🙏 Acknowledgments

- [Amazon Polly](https://aws.amazon.com/polly/) - Text-to-speech technology
- [AWS Lambda](https://aws.amazon.com/lambda/) - Serverless computing
- [AWS SDK for JavaScript](https://aws.amazon.com/sdk-for-javascript/)

## 📞 Support

- 📫 [Open an issue](https://github.com/yourusername/text-to-speech/issues)
- 📖 [AWS Polly Docs](https://docs.aws.amazon.com/polly/)
- 📖 [AWS Lambda Docs](https://docs.aws.amazon.com/lambda/)

## 👨‍💻 Author

**Your Name**
- GitHub: [@yourusername](https://github.com/kahramanmurat)
- LinkedIn: [Your Profile](https://www.linkedin.com/in/kahramanmurat)

---

⭐ **Star this repo if you find it helpful!**

Made with ❤️ using AWS Services
