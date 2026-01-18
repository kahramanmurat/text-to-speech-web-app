const { PollyClient, SynthesizeSpeechCommand } = require('@aws-sdk/client-polly');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { GetObjectCommand } = require('@aws-sdk/client-s3');
const { v4: uuidv4 } = require('uuid');

const pollyClient = new PollyClient();
const s3Client = new S3Client();

// Environment variables (set these in Lambda configuration)
const BUCKET_NAME = process.env.S3_BUCKET_NAME || 'your-audio-bucket-name';
const AUDIO_EXPIRY = 3600; // URL expiration time in seconds (1 hour)

exports.handler = async (event) => {
    console.log('Received event:', JSON.stringify(event, null, 2));

    // CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Content-Type': 'application/json'
    };

    // Handle preflight OPTIONS request
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers: headers,
            body: ''
        };
    }

    try {
        // Parse request body
        let body;
        try {
            body = JSON.parse(event.body);
        } catch (error) {
            return {
                statusCode: 400,
                headers: headers,
                body: JSON.stringify({
                    error: 'Invalid JSON in request body'
                })
            };
        }

        const { text, voiceId, languageCode } = body;

        // Validation
        if (!text || text.trim().length === 0) {
            return {
                statusCode: 400,
                headers: headers,
                body: JSON.stringify({
                    error: 'Text is required'
                })
            };
        }

        if (text.length > 3000) {
            return {
                statusCode: 400,
                headers: headers,
                body: JSON.stringify({
                    error: 'Text is too long. Maximum 3000 characters allowed.'
                })
            };
        }

        // Default values
        const voice = voiceId || 'Joanna';
        const language = languageCode || 'en-US';

        console.log(`Converting text to speech - Voice: ${voice}, Language: ${language}`);

        // Step 1: Synthesize speech using Amazon Polly
        const pollyParams = {
            Text: text,
            OutputFormat: 'mp3',
            VoiceId: voice,
            LanguageCode: language,
            Engine: 'neural' // Use neural engine for better quality (fallback to standard if not available)
        };

        let audioStream;
        try {
            const pollyCommand = new SynthesizeSpeechCommand(pollyParams);
            const pollyResponse = await pollyClient.send(pollyCommand);

            // Convert stream to buffer
            const chunks = [];
            for await (const chunk of pollyResponse.AudioStream) {
                chunks.push(chunk);
            }
            audioStream = Buffer.concat(chunks);
        } catch (pollyError) {
            // If neural engine fails, try standard engine
            console.log('Neural engine failed, trying standard engine:', pollyError.message);
            pollyParams.Engine = 'standard';
            const pollyCommand = new SynthesizeSpeechCommand(pollyParams);
            const pollyResponse = await pollyClient.send(pollyCommand);

            // Convert stream to buffer
            const chunks = [];
            for await (const chunk of pollyResponse.AudioStream) {
                chunks.push(chunk);
            }
            audioStream = Buffer.concat(chunks);
        }

        // Step 2: Upload audio file to S3
        const fileName = `speech-${uuidv4()}.mp3`;
        const s3Params = {
            Bucket: BUCKET_NAME,
            Key: fileName,
            Body: audioStream,
            ContentType: 'audio/mpeg',
            CacheControl: 'max-age=3600'
        };

        const putCommand = new PutObjectCommand(s3Params);
        await s3Client.send(putCommand);
        console.log(`Audio file uploaded to S3: ${fileName}`);

        // Step 3: Generate public URL for the audio file (no presigned URL needed)
        const audioUrl = `https://${BUCKET_NAME}.s3.amazonaws.com/${fileName}`;

        // Return success response
        return {
            statusCode: 200,
            headers: headers,
            body: JSON.stringify({
                message: 'Text successfully converted to speech',
                audioUrl: audioUrl,
                fileName: fileName,
                voice: voice,
                language: language,
                expiresIn: AUDIO_EXPIRY
            })
        };

    } catch (error) {
        console.error('Error:', error);

        return {
            statusCode: 500,
            headers: headers,
            body: JSON.stringify({
                error: 'Failed to convert text to speech',
                message: error.message
            })
        };
    }
};
