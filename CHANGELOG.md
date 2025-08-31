## v4.0.0

High-level changes:

- New: Weather Chat experience (models, provider, service, and UI with context header and suggestion chips)
- New: Agriculture screen with Drought Monitor and Soil Moisture (providers, services, and cards)
- UI: Forecast improvements with new hourly/daily list items and detail dialogs
- Infra/Security: Removed API keys from version control; added `lib/config/api_config.template.dart`; expanded `.gitignore` to ignore secrets and Firebase configs
- Backend (Cloud Functions): Added AI/chat support services and summarization logic
- Core updates: `weather_screen`, `weather_service`, `forecast_card`, `main_app_container`, and navigation config adjusted for new features
- Dependencies updated and app version bumped to 4.0.0


## v4.1.0

Theme engine modernization and cleanup

- New: Modern theme engine based on `ThemeData`/`ColorScheme` with a `GlassThemeExtension`
- New: User-customizable theming (primary/accent colors) with local persistence via `SharedPreferences`
- New: Optional Material You dynamic color (Android 12+) behind an opt-in toggle
- New: Auto (sunrise/sunset) mode that switches between light/dark based on current location (with fallbacks)
- Accessibility: Automatic contrast enforcement for on-colors and key components
- UI: Removed weather-based gradients and visuals; updated screens and widgets to consume theme tokens
- Cleanup: Removed deprecated weather gradient APIs and legacy color usages
- Docs: Updated README to reflect the new theme engine and features

