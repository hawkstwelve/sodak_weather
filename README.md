# SoDak Weather

A beautiful, performance-optimized weather application for South Dakota built with Flutter. This app provides current weather conditions, hourly and daily forecasts, and Area Forecast Discussion (AFD) information from the National Weather Service.

![SoDak Weather App](assets/splash.png)

## Features

- **Current Weather Conditions**: Real-time weather data for South Dakota cities
- **Hourly Forecast**: Detailed hourly weather predictions
- **Daily Forecast**: 10-day weather outlook
- **Area Forecast Discussion**: Detailed meteorological analysis from NWS meteorologists
- **Multiple Locations**: Support for major South Dakota cities
- **Beautiful UI**: Modern, glass-morphic interface with dynamic backgrounds based on weather conditions
- **Performance Optimized**: Designed for smooth performance on all devices

## APIs Used

The app integrates with two primary weather APIs:

1. **Google Weather API**
   - Provides current conditions and forecast data
   - Base URL: `https://weather.googleapis.com/v1`
   - Endpoints used:
     - `/currentConditions:lookup` - Current weather data
     - `/forecast:lookup` - 10-day forecast
     - `/hourlyForecast:lookup` - Hourly forecast

2. **National Weather Service (NWS) API**
   - Used for Area Forecast Discussion (AFD)
   - Base URL: `https://api.weather.gov`
   - Endpoints used:
     - `/products/types/AFD/locations/{office}` - AFD by NWS office

## Project Structure

```
lib/
├── main.dart              # App entry point and configuration
├── models/                # Data models
│   ├── hourly_forecast.dart     # Hourly forecast data model
│   ├── sd_city.dart             # South Dakota cities model
│   └── weather_data.dart        # Weather data models
├── screens/               # App screens
│   ├── afd_screen.dart          # Area Forecast Discussion screen
│   └── weather_screen.dart      # Main weather screen
├── services/              # API services
│   └── weather_service.dart     # Weather API integration
├── theme/                 # App styling
│   └── app_theme.dart           # Global theme configuration
├── utils/                 # Helper utilities
│   ├── sun_utils.dart                   # Sunrise/sunset calculations
│   └── weather_utils.dart               # Weather-related helper functions
└── widgets/               # Reusable UI components
    ├── app_drawer.dart           # Navigation drawer
    ├── forecast_card.dart        # Daily forecast card
    ├── hourly_forecast_card.dart # Hourly forecast card
    └── glass/                    # Glass effect components
        ├── glass_card.dart            # Glassmorphic card component
        ├── glass_container.dart       # Glass container with blur effect
        └── frosted_background.dart    # Frosted background for screens
```

## Key Components

### Models

- `SDCity` - Represents South Dakota cities with location data and NWS office identifiers
- `WeatherData` - Contains current conditions and forecast data
- `HourlyForecast` - Represents hourly weather data points

### Screens

- `WeatherScreen` - The main screen showing current weather and forecasts
- `AFDScreen` - Displays the Area Forecast Discussion text from NWS

### Services

- `WeatherService` - Handles API communication for weather data retrieval

### Widgets

- `GlassCard/GlassContainer` - Creates a frosted glass effect for UI elements
- `ForecastCard` - Displays daily forecast information
- `HourlyForecastCard` - Displays hourly forecast information
- `FrostedBackground` - Creates a gradient background for screens

### Theme

- `AppTheme` - Contains app-wide styling including colors, text styles, and themes

## UI Design

The app uses a modern glassmorphic design language with:

- Frosted glass panels for content
- Dynamic gradient backgrounds that change based on weather conditions
- Weather condition-specific icons and color schemes
- Optimized performance for smooth animations and transitions

## Performance Optimizations

- Custom-built glassmorphism effects optimized for mobile performance
- Efficient widget rebuilds and state management
- Image caching for weather icons
- Portrait orientation lock for better experience
- Reduced transparency and effects on lower-end devices

## Getting Started

### Prerequisites

- Flutter SDK (Version ^3.8.1)
- Dart SDK (Version ^3.8.1)
- A Google Weather API key

### Installation

1. Clone the repository
```bash
git clone https://your-repository-url/sodak_weather.git
cd sodak_weather
```

2. Install dependencies
```bash
flutter pub get
```

3. Update the API key in `lib/services/weather_service.dart`

4. Run the app
```bash
flutter run
```

### Building for Release

For Android:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

For iOS:
```bash
flutter build ios --release
```

## Future Enhancements

- Push notifications for severe weather alerts
- Weather radar integration
- User location detection
- Weather station selection
- Historical weather data
- Weather widgets for home screen

## Credits

- Weather data provided by Google Weather API and National Weather Service
- Weather icons from [OpenWeatherMap](https://openweathermap.org/weather-conditions)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
