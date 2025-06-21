# API Key Setup Guide

## Security Issue Fixed

Both the Stadia Maps API key and Google Weather API key were previously hardcoded in the source code, which is a security risk. This has been fixed by implementing a secure configuration system.

## How to Set Up Your API Keys

### Option 1: Using Environment Variables (Recommended for Production)

1. **Get your API keys:**
   - **Stadia Maps API key** from [Stadia Maps](https://stadiamaps.com/) (free tier available)
   - **Google Weather API key** from [Google Cloud Console](https://console.cloud.google.com/) (enable Weather API)

2. **Set the environment variables** when building the app:
   ```bash
   flutter build apk --dart-define=STADIA_MAPS_API_KEY=your_stadia_api_key --dart-define=GOOGLE_API_KEY=your_google_api_key
   ```

   Or for iOS:
   ```bash
   flutter build ios --dart-define=STADIA_MAPS_API_KEY=your_stadia_api_key --dart-define=GOOGLE_API_KEY=your_google_api_key
   ```

### Option 2: Using .env File (Development)

1. Create a `.env` file in the project root:
   ```
   STADIA_MAPS_API_KEY=your_stadia_api_key_here
   GOOGLE_API_KEY=your_google_api_key_here
   ```

2. The `.env` file is already added to `.gitignore` to prevent it from being committed.

### Option 3: Direct Configuration (Quick Setup)

1. Edit `lib/config/api_config.dart`
2. Replace the placeholder values:
   - `'your_api_key_here'` with your Stadia Maps API key
   - `'your_google_api_key_here'` with your Google API key
3. **Important**: Make sure this file is not committed to version control

## Security Best Practices

- ✅ Never commit API keys to version control
- ✅ Use environment variables in production
- ✅ The `.env` file is already in `.gitignore`
- ✅ API keys are now centralized in `lib/config/api_config.dart`

## What Was Changed

1. **Removed hardcoded API keys** from:
   - `lib/screens/radar_screen.dart` (Stadia Maps)
   - `lib/widgets/radar_card.dart` (Stadia Maps)
   - `lib/services/weather_service.dart` (Google Weather API)

2. **Added secure configuration** in:
   - `lib/config/api_config.dart` (both API keys)

3. **Updated .gitignore** to exclude environment files

4. **Added flutter_dotenv** dependency for environment variable support

## Next Steps

1. **Regenerate both API keys** since they were exposed in version control:
   - Stadia Maps API key
   - Google Weather API key

2. **Set up the new API keys** using one of the methods above

3. **Test the functionality** to ensure both weather data and radar work properly

4. **Consider using environment variables** in production for maximum security

## Support

If you need help setting up your API keys or have questions about the security implementation, please refer to:
- [Stadia Maps Documentation](https://docs.stadiamaps.com/)
- [Google Weather API Documentation](https://developers.google.com/maps/documentation/weather)
- Create an issue in the repository for additional support 