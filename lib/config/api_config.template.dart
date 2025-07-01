// Template file for API configuration
// Copy this file to lib/config/api_config.dart and replace the placeholder values with your actual API keys

class ApiConfig {
  // Google Weather API Key
  static const String googleWeatherApiKey = 'YOUR_GOOGLE_WEATHER_API_KEY_HERE';
  
  // Stadia Maps API Key  
  static const String stadiaMapsApiKey = 'YOUR_STADIA_MAPS_API_KEY_HERE';
  
  // RainViewer API (no key required)
  static const String rainviewerApiUrl = 'https://api.rainviewer.com/public/weather-maps.json';
  
  // Base URLs
  static const String weatherApiBaseUrl = 'https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline';
  static const String nwsApiBaseUrl = 'https://api.weather.gov';
  static const String spcApiBaseUrl = 'https://www.spc.noaa.gov/products/outlook';
  
  // Tile URLs for maps
  static const String lightTileUrl = 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png';
  static const String darkTileUrl = 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png';
  
  // Radar configuration
  static const double radarInitialZoom = 8.0;
  static const double radarMinZoom = 4.0;
  static const double radarMaxZoom = 12.0;
  static const double radarOpacity = 0.7;
  
  // Weather refresh intervals
  static const Duration weatherRefreshInterval = Duration(minutes: 15);
  static const Duration radarRefreshInterval = Duration(minutes: 5);
} 