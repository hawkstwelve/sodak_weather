// Template file for API configuration
// Copy this file to api_config.dart and replace the placeholder values with your actual API keys
// IMPORTANT: Never commit the actual api_config.dart file with real API keys

class ApiConfig {
  // Stadia Maps API Key
  // Get your free API key from: https://stadiamaps.com/
  static const String stadiaMapsApiKey = String.fromEnvironment(
    'STADIA_MAPS_API_KEY',
    defaultValue: 'your_stadia_maps_api_key_here',
  );
  
  // Google Weather API Key
  // Get your API key from: https://console.cloud.google.com/ (enable Weather API)
  static const String googleApiKey = String.fromEnvironment(
    'GOOGLE_API_KEY',
    defaultValue: 'your_google_api_key_here',
  );
  
  // Base URLs for Stadia Maps tiles
  static String get lightTileUrl => 
    'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png?api_key=$stadiaMapsApiKey';
  
  static String get darkTileUrl => 
    'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png?api_key=$stadiaMapsApiKey';
} 