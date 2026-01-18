#!/bin/bash

# Test script for Text-to-Speech API
# Usage: ./test-api.sh <API_GATEWAY_URL>

if [ -z "$1" ]; then
    echo "Usage: ./test-api.sh <API_GATEWAY_URL>"
    echo "Example: ./test-api.sh https://abc123.execute-api.us-east-1.amazonaws.com/prod/text-to-speech"
    exit 1
fi

API_URL="$1"

echo "Testing Text-to-Speech API"
echo "API URL: $API_URL"
echo ""

# Test 1: Simple conversion
echo "Test 1: Simple text conversion"
RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{
        "text": "Hello, this is a test of the text to speech system.",
        "voiceId": "Joanna",
        "languageCode": "en-US"
    }')

echo "Response:"
echo "$RESPONSE" | jq '.'
echo ""

# Check if audioUrl exists
if echo "$RESPONSE" | jq -e '.audioUrl' > /dev/null; then
    echo "✓ Test 1 passed: Audio URL generated"
else
    echo "✗ Test 1 failed: No audio URL in response"
fi
echo ""

# Test 2: Different voice
echo "Test 2: British voice (Brian)"
RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{
        "text": "Good day! This is a test with a British accent.",
        "voiceId": "Brian",
        "languageCode": "en-GB"
    }')

if echo "$RESPONSE" | jq -e '.audioUrl' > /dev/null; then
    echo "✓ Test 2 passed: British voice conversion successful"
else
    echo "✗ Test 2 failed"
fi
echo ""

# Test 3: Empty text (should fail)
echo "Test 3: Empty text validation"
RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{
        "text": "",
        "voiceId": "Joanna",
        "languageCode": "en-US"
    }')

if echo "$RESPONSE" | jq -e '.error' > /dev/null; then
    echo "✓ Test 3 passed: Empty text properly rejected"
else
    echo "✗ Test 3 failed: Should reject empty text"
fi
echo ""

# Test 4: Long text
echo "Test 4: Long text conversion"
LONG_TEXT="This is a longer text to test the system's ability to handle more substantial content. Amazon Polly is a service that turns text into lifelike speech, allowing you to create applications that talk, and build entirely new categories of speech-enabled products. Polly's Text-to-Speech service uses advanced deep learning technologies to synthesize natural sounding human speech."

RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{
        \"text\": \"$LONG_TEXT\",
        \"voiceId\": \"Matthew\",
        \"languageCode\": \"en-US\"
    }")

if echo "$RESPONSE" | jq -e '.audioUrl' > /dev/null; then
    echo "✓ Test 4 passed: Long text conversion successful"
else
    echo "✗ Test 4 failed"
fi
echo ""

echo "========================================"
echo "Testing completed!"
echo "========================================"
