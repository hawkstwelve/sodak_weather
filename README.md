# SoDak Weather

A beautiful, performance-optimized weather application for South Dakota built with Flutter. This app provides current weather conditions, hourly and daily forecasts, weather radar, severe weather alerts, and Area Forecast Discussion (AFD) information from the National Weather Service.

![SoDak Weather App](assets/splash.png)

## Features

- **Current Weather Conditions**: Real-time weather data for South Dakota cities
- **Hourly Forecast**: Detailed hourly weather predictions
- **Daily Forecast**: 10-day weather outlook
- **Weather Radar**: Interactive radar maps with animation support
- **Severe Weather Alerts**: Real-time NWS weather alerts and warnings
- **SPC Outlooks**: Storm Prediction Center severe weather outlooks
- **Area Forecast Discussion**: Detailed meteorological analysis from NWS meteorologists
- **Multiple Locations**: Support for major South Dakota cities
- **Beautiful UI**: Modern, glassmorphic interface with dynamic backgrounds based on weather conditions
- **Performance Optimized**: Designed for smooth performance on all devices

## APIs Used

The app integrates with multiple weather APIs:

1. **Google Weather API**
   - Provides current conditions and forecast data
   - Base URL: `https://weather.googleapis.com/v1`
   - Endpoints used:
     - `/currentConditions:lookup` - Current weather data
     - `/forecast:lookup` - 10-day forecast
     - `/hourlyForecast:lookup` - Hourly forecast

2. **National Weather Service (NWS) API**
   - Used for Area Forecast Discussion (AFD) and weather alerts
   - Base URL: `https://api.weather.gov`
   - Endpoints used:
     - `/products/types/AFD/locations/{office}` - AFD by NWS office
     - `/alerts/active` - Active weather alerts
     - `/gridpoints/{office}/{x},{y}/forecast` - Grid-based forecasts

3. **RainViewer API**
   - Provides weather radar data and imagery
   - Base URL: `https://api.rainviewer.com`
   - Endpoints used:
     - `/public/weather-maps.json` - Radar timestamps
     - `/public/weather-maps/{timestamp}/{z}/{x}/{y}/{color}/{smooth}.png` - Radar tiles

4. **Storm Prediction Center (SPC) API**
   - Provides severe weather outlooks
   - Base URL: `https://www.spc.noaa.gov`
   - Endpoints used:
     - `/products/outlook/day1otlk_cat.nolyr.geojson` - Day 1 outlook
     - `/products/outlook/day2otlk_cat.nolyr.geojson` - Day 2 outlook
     - `/products/outlook/day3otlk_cat.nolyr.geojson` - Day 3 outlook

## Project Structure

```
lib/
├── main.dart              # App entry point and configuration
├── models/                # Data models
│   ├── hourly_forecast.dart     # Hourly forecast data model
│   ├── nws_alert_model.dart     # NWS alert data model
│   ├── sd_city.dart             # South Dakota cities model
│   ├── spc_outlook.dart         # SPC outlook data model
│   └── weather_data.dart        # Weather data models
├── providers/             # State management
│   └── weather_provider.dart    # Weather data provider
├── screens/               # App screens
│   ├── afd_screen.dart          # Area Forecast Discussion screen
│   ├── radar_screen.dart        # Weather radar screen
│   ├── spc_outlooks_screen.dart # SPC outlooks screen
│   └── weather_screen.dart      # Main weather screen
├── services/              # API services
│   ├── afd_service.dart         # AFD service
│   ├── nws_alert_service.dart   # NWS alerts service
│   ├── rainviewer_api.dart      # Radar API service
│   ├── spc_outlook_service.dart # SPC outlooks service
│   └── weather_service.dart     # Weather API integration
├── theme/                 # App styling
│   └── app_theme.dart           # Global theme configuration
├── utils/                 # Helper utilities
│   ├── hour_utils.dart                   # Hour calculations
│   ├── sun_utils.dart                    # Sunrise/sunset calculations
│   └── weather_utils.dart                # Weather-related helper functions
└── widgets/               # Reusable UI components
    ├── app_drawer.dart           # Navigation drawer
    ├── forecast_card.dart        # Daily forecast card
    ├── glass_card_scroll_view.dart # Optimized scroll view
    ├── hourly_forecast_card.dart # Hourly forecast card
    ├── main_app_container.dart   # Main app container
    ├── nws_alert_banner.dart     # Weather alert banner
    ├── precipitation_chart.dart  # Precipitation chart
    ├── radar_card.dart           # Radar preview card
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
- `NWSAlert` - Weather alert and warning data
- `SPCOutlook` - Storm Prediction Center outlook data

### Screens

- `WeatherScreen` - The main screen showing current weather and forecasts
- `RadarScreen` - Interactive weather radar with animation
- `SPCOutlooksScreen` - Storm Prediction Center outlooks
- `AFDScreen` - Displays the Area Forecast Discussion text from NWS

### Services

- `WeatherService` - Handles Google Weather API communication
- `RainViewerAPI` - Manages radar data and imagery
- `NWSAlertService` - Handles weather alerts and warnings
- `SPCOutlookService` - Manages SPC outlook data
- `AFDService` - Handles Area Forecast Discussion data

### Widgets

- `GlassCard/GlassContainer` - Creates a frosted glass effect for UI elements
- `ForecastCard` - Displays daily forecast information
- `HourlyForecastCard` - Displays hourly forecast information
- `RadarCard` - Radar preview and navigation
- `NWSAlertBanner` - Weather alert notifications
- `PrecipitationChart` - Precipitation visualization
- `FrostedBackground` - Creates a gradient background for screens

### Theme

- `AppTheme` - Contains app-wide styling including colors, text styles, and themes
- **Inter Font** - Modern typography via Google Fonts

## UI Design

The app uses a modern glassmorphic design language with:

- Frosted glass panels for content with performance optimizations
- Dynamic gradient backgrounds that change based on weather conditions
- Weather condition-specific icons and color schemes
- Optimized performance for smooth animations and transitions
- Modern Inter font family for clean typography

## Performance Optimizations

- **Glass Effect Optimization**: Custom-built glassmorphism with performance considerations
- **Radar Performance**: Optimized tile loading and caching for smooth radar experience
- **Efficient Widget Rebuilds**: Smart state management to minimize unnecessary rebuilds
- **Image Caching**: Weather icons and radar tiles are cached for better performance
- **Scroll Optimization**: Custom scroll views for glass cards in lists
- **Memory Management**: Proper disposal of resources and controllers

## Getting Started

### Prerequisites

- Flutter SDK (Version ^3.8.1)
- Dart SDK (Version ^3.8.1)
- A Google Weather API key

### Installation

1. Clone the repository
```bash
git clone https://github.com/hawkstwelve/sodak_weather.git
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
- User location detection
- Weather station selection
- Historical weather data
- Weather widgets for home screen
- Additional radar products (velocity, reflectivity)
- Weather camera integration

## Credits

- Weather data provided by Google Weather API and National Weather Service
- Radar data provided by RainViewer
- Severe weather outlooks from Storm Prediction Center
- Weather icons from [OpenWeatherMap](https://openweathermap.org/weather-conditions)
- Typography: Inter font via Google Fonts

## License

This project is licensed under the MIT License - see the LICENSE file for details.
