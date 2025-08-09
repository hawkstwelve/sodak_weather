# SoDak Weather v4.0.0

This release brings a chat-based weather experience, agriculture insights, and several UI/infra improvements.

## Highlights

- Weather Chat
  - Chat UI with context header and quick suggestion chips
  - Models, provider, and service for chat sessions/messages
  - Cloud Functions to process and summarize weather context
- Agriculture
  - New Agriculture screen
  - Drought Monitor and Soil Moisture providers, services, and cards
- Forecast UX
  - New hourly and daily list item widgets
  - Detail dialogs for hourly/daily forecasts
- Security & Config
  - Removed API keys and sensitive files from version control
  - Template lib/config/api_config.template.dart for local setup
  - Updated .gitignore to keep secrets private
- Core Updates
  - Improvements to weather_screen, weather_service, forecast_card, and main_app_container
  - Navigation updated to include new features
- Dependencies upgraded

## Setup Notes

- Follow API_SETUP.md to configure your own API keys locally. Ensure lib/config/api_config.dart, Firebase configuration files, and lib/firebase_options.dart remain untracked.

## Android APK

- A release APK is attached to this GitHub release.
