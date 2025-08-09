# Firebase Functions - Weather Chat

This directory contains the Firebase Functions for the Sodak Weather app's AI weather chatbot.

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Environment Variables

The weather chat function requires the following environment variables to be set in Firebase:

#### Google Weather API Key
```bash
firebase functions:config:set google.weather_api_key="YOUR_GOOGLE_WEATHER_API_KEY"
```

#### AI Service Configuration
```bash
# For OpenAI (if using OpenAI instead of Gemini)
firebase functions:config:set openai.api_key="YOUR_OPENAI_API_KEY"

# For Google Gemini (if using Gemini)
firebase functions:config:set google.gemini_api_key="YOUR_GEMINI_API_KEY"
```

### 3. Local Development

To run the functions locally:

```bash
npm run serve
```

This will start the Firebase emulator with the functions.

### 4. Deployment

To deploy the functions to Firebase:

```bash
npm run deploy
```

## Functions

### weatherChat

The main weather chat function that:
- Fetches real weather data from Google Weather API
- Fetches NWS alerts for the location
- Processes user questions with AI
- Provides South Dakota-specific weather context
- Caches responses for performance
- Implements rate limiting

## API Endpoints

### POST /weatherChat

**Request Body:**
```json
{
  "question": "What's the weather like today?",
  "location": "Sioux Falls"
}
```

**Response:**
```json
{
  "result": "AI response text",
  "cached": false,
  "weatherContext": "weather summary",
  "questionAnalysis": {
    "timeFrame": "current",
    "weatherType": "general",
    "urgency": "low",
    "southDakotaContext": "general"
  }
}
```

## Location Support

The function supports the following South Dakota locations:
- Sioux Falls
- Rapid City
- Pierre
- Aberdeen
- Brookings
- Black Hills (maps to Rapid City)
- Eastern SD (maps to Sioux Falls)
- Western SD (maps to Rapid City)
- Current Location (defaults to Sioux Falls)

## Error Handling

The function includes comprehensive error handling:
- Rate limiting (20 requests per hour per user)
- Fallback responses when APIs are unavailable
- Graceful degradation for missing weather data
- Caching to reduce API calls

## Monitoring

Check function logs:
```bash
firebase functions:log
```

## Dependencies

- `firebase-admin`: Firebase Admin SDK
- `firebase-functions`: Firebase Functions framework
- `node-fetch`: HTTP requests for weather APIs
- `@google/generative-ai`: Google Gemini AI
- `openai`: OpenAI API (alternative AI provider)
- `crypto`: Cryptographic functions for caching 