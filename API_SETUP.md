# API Setup Guide

## Required API Keys

This app requires several API keys to function properly. Follow these steps to set up your development environment:

### 1. Google Weather API
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Weather API
4. Create credentials (API Key)
5. Copy the API key

### 2. Stadia Maps API (Optional - for map tiles)
1. Go to [Stadia Maps](https://stadiamaps.com/)
2. Create an account and get your API key
3. Copy the API key

### 3. Firebase Configuration (for notifications and backend)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Add Android and iOS apps to your project
4. Download the configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
5. Generate `firebase_options.dart` using FlutterFire CLI

## Setup Steps

### 1. API Configuration
1. Copy `lib/config/api_config.template.dart` to `lib/config/api_config.dart`
2. Replace the placeholder values with your actual API keys:
   ```dart
   static const String googleWeatherApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   static const String stadiaMapsApiKey = 'YOUR_ACTUAL_STADIA_API_KEY_HERE';
   ```

### 2. Firebase Configuration
1. Place `google-services.json` in `android/app/`
2. Place `GoogleService-Info.plist` in `ios/Runner/`
3. Place `firebase_options.dart` in `lib/`

### 3. Environment Variables (Alternative)
Instead of hardcoding API keys, you can use environment variables:
1. Create a `.env` file in the project root
2. Add your API keys:
   ```
   GOOGLE_WEATHER_API_KEY=your_api_key_here
   STADIA_MAPS_API_KEY=your_stadia_key_here
   ```
3. Update `lib/config/api_config.dart` to read from environment variables

## Security Notes

- **NEVER commit API keys to version control**
- The following files are ignored by git:
  - `lib/config/api_config.dart`
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
  - `lib/firebase_options.dart`
  - `.env`

- For production builds, use GitHub Secrets to inject API keys during the build process

## Troubleshooting

If you encounter issues:
1. Verify API keys are correctly set
2. Check API quotas and billing
3. Ensure Firebase project is properly configured
4. Verify app bundle ID matches Firebase configuration 