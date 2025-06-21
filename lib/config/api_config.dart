class ApiConfig {
  // Stadia Maps API Key
  // In production, this should be loaded from environment variables
  // For now, you can set your API key here, but make sure to add this file to .gitignore
  // or use environment variables in production
  static const String stadiaMapsApiKey = String.fromEnvironment(
    'STADIA_MAPS_API_KEY',
    defaultValue: 'your_api_key_here',
  );
  
  // Google Weather API Key
  // In production, this should be loaded from environment variables
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