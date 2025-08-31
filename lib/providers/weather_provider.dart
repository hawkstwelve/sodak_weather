import 'package:flutter/material.dart';
import '../models/sd_city.dart';
import '../models/weather_data.dart';
import '../models/hourly_forecast.dart';
import '../models/nws_alert_model.dart';
import '../services/weather_service.dart';
import '../services/nws_alert_service.dart';
import '../utils/sun_utils.dart';
import 'location_provider.dart';
import 'package:geolocator/geolocator.dart';

/// Manages the state for weather-related data.
///
/// This provider handles fetching all weather data, managing the selected city,
/// and notifying listeners of any changes to the state (e.g., loading, error, success).
class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  LocationProvider? _locationProvider;

  // Private state variables
  SDCity _selectedCity = SDCities.siouxFalls;
  WeatherData? _weatherData;
  List<HourlyForecast>? _hourlyForecast;
  List<NwsAlertFeature> _nwsAlerts = [];
  String? _aqiCategory;
  double? _rain24hInches;
  bool _isUsingLocation = false;

  bool _isLoading = false;
  String? _errorMessage;

  // Public getters to access state
  SDCity get selectedCity => _selectedCity;
  WeatherData? get weatherData => _weatherData;
  List<HourlyForecast>? get hourlyForecast => _hourlyForecast;
  List<NwsAlertFeature> get nwsAlerts => _nwsAlerts;
  String? get aqiCategory => _aqiCategory;
  double? get rain24hInches => _rain24hInches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUsingLocation => _isUsingLocation;
  bool get isInitialized => _locationProvider != null;

  // Expose the weather service to access lastRawForecastData if needed
  WeatherService get weatherService => _weatherService;

  // Get sunrise/sunset events for today and tomorrow
  Map<String, Map<String, DateTime?>> get sunEvents => {
    'today': {
      'sunrise': _weatherData?.sunrise,
      'sunset': _weatherData?.sunset,
    },
    'tomorrow': {
      'sunrise': _weatherData?.tomorrowSunrise,
      'sunset': _weatherData?.tomorrowSunset,
    },
  };

  WeatherProvider() {
    // Ensure selectedCity is always initialized with a default value
    _selectedCity = SDCities.siouxFalls;
    // Don't fetch initial weather data here - wait for location provider to be set
    // fetchAllWeatherData();
  }

  /// Set the location provider reference
  Future<void> setLocationProvider(LocationProvider locationProvider) async {
    _locationProvider = locationProvider;
    
    try {
      // Wait for location provider to finish initializing
      await _locationProvider!.initializationDone;
      // After setting the location provider, check if we should use cached location
      await _initializeWithCachedLocation();
      
      // Notify listeners that initialization is complete
      notifyListeners();
    } catch (e) {
      // If initialization fails, fall back to default city
      _isUsingLocation = false;
      _selectedCity = SDCities.siouxFalls;
      notifyListeners();
    }
  }

  /// Initialize with cached location if available, otherwise use default city
  Future<void> _initializeWithCachedLocation() async {
    if (_locationProvider == null) {
      // Fall back to default city if no location provider
      _isUsingLocation = false;
      _selectedCity = SDCities.siouxFalls;
      notifyListeners();
      return;
    }

    try {
      // Refresh permission status to ensure we have the latest state
      await _locationProvider!.refreshPermissionStatus();
      
      // Always prefer device location if permission is granted and location is available
      final permission = _locationProvider!.permissionStatus;
      final hasLocation = _locationProvider!.hasLocation;
      final isPermissionGranted =
          permission == LocationPermission.always || permission == LocationPermission.whileInUse;

      if (isPermissionGranted && hasLocation) {
        _isUsingLocation = true;
        notifyListeners(); // Notify immediately when flag changes
        await fetchAllWeatherDataForCoordinates(
          _locationProvider!.currentLocation!.latitude,
          _locationProvider!.currentLocation!.longitude,
        );
      } else {
        _isUsingLocation = false;
        _selectedCity = SDCities.siouxFalls;
        fetchAllWeatherData();
      }
    } catch (e) {
      // If anything fails, fall back to default city
      _isUsingLocation = false;
      _selectedCity = SDCities.siouxFalls;
      notifyListeners();
    }
  }

  /// Sets the selected city and fetches new weather data for it.
  void setSelectedCity(SDCity city) {
    if (_selectedCity.name != city.name || _isUsingLocation) {
      _selectedCity = city;
      _isUsingLocation = false;
      notifyListeners(); // Notify immediately when flag changes
      fetchAllWeatherData();
      
      // Sync location change with backend for notifications
      _syncLocationChange();
    }
  }

  /// Set the app to use current location without fetching location again
  /// This is useful when location has already been obtained elsewhere
  void setUsingLocation(bool useLocation) {
    if (_isUsingLocation != useLocation) {
      _isUsingLocation = useLocation;
      notifyListeners();
    }
  }

  /// Refresh the location provider's permission status
  Future<void> refreshLocationPermissions() async {
    if (_locationProvider != null) {
      await _locationProvider!.refreshPermissionStatus();
    }
  }

  /// Fetch weather for current location
  Future<bool> fetchWeatherForLocation() async {
    if (_locationProvider == null) {
      _errorMessage = 'Location provider not available';
      notifyListeners();
      return false;
    }

    final success = await _locationProvider!.getCurrentLocation();
    if (success && _locationProvider!.currentLocation != null) {
      _isUsingLocation = true;
      notifyListeners(); // Notify immediately when flag changes
      
      // Check if we're using cached location
      final isUsingCached = _locationProvider!.isUsingCachedLocation;
      
      await fetchAllWeatherDataForCoordinates(
        _locationProvider!.currentLocation!.latitude,
        _locationProvider!.currentLocation!.longitude,
      );
      
      // If using cached location, show a brief message
      if (isUsingCached && _locationProvider!.cacheAgeMinutes != null) {
        // The cache status will be handled by the UI components
        // that listen to the location provider
      }
      
      // Sync location change with backend for notifications
      _syncLocationChange();
      
      return true;
    } else {
      _errorMessage = _locationProvider!.errorMessage ?? 'Unable to get location';
      notifyListeners();
      return false;
    }
  }

  /// Force refresh location and weather data
  Future<bool> refreshLocationWeather() async {
    if (_locationProvider == null) {
      _errorMessage = 'Location provider not available';
      notifyListeners();
      return false;
    }

    final success = await _locationProvider!.refreshLocation();
    if (success && _locationProvider!.currentLocation != null) {
      _isUsingLocation = true;
      notifyListeners(); // Notify immediately when flag changes
      await fetchAllWeatherDataForCoordinates(
        _locationProvider!.currentLocation!.latitude,
        _locationProvider!.currentLocation!.longitude,
      );
      
      // Sync location change with backend for notifications
      _syncLocationChange();
      
      return true;
    } else {
      _errorMessage = _locationProvider!.errorMessage ?? 'Unable to refresh location';
      notifyListeners();
      return false;
    }
  }

  /// Sync location change with backend for notifications
  void _syncLocationChange() {
    // This will be called by the notification service when providers are set
    // We'll trigger a notify to ensure the notification service picks up the change
    notifyListeners();
  }

  /// Fetch weather data for specific coordinates
  Future<void> fetchAllWeatherDataForCoordinates(double latitude, double longitude) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _weatherService.getCurrentWeather(latitude: latitude, longitude: longitude),
        _weatherService.getHourlyForecast(latitude: latitude, longitude: longitude),
        _weatherService.fetchAqiCategory(
          latitude: latitude,
          longitude: longitude,
        ),
        _weatherService.fetch24HourPrecipitationTotal(
          latitude: latitude,
          longitude: longitude,
        ),
        NwsAlertService.fetchAlertsForCoordinates(latitude, longitude),
      ]);

      // Process results
      final rawWeatherData = results[0] as Map<String, dynamic>;
      final hourlyData = results[1] as List<HourlyForecast>;
      final aqiResult = results[2] as Map<String, String?>?;
      final rainTotals = results[3] as Map<String, double>?;
      final alertCollection = results[4] as NwsAlertCollection?;

      // --- Calculate Sunrise/Sunset ---
      DateTime? sunrise;
      DateTime? sunset;
      DateTime? tomorrowSunrise;
      DateTime? tomorrowSunset;
      if (rawWeatherData['forecast']?['forecastDays'] != null) {
        final todaySunEvents = getSunriseSunsetForDate(
          rawWeatherData['forecast']['forecastDays'],
          DateTime.now(),
          timeZoneId: rawWeatherData['forecast']?['timeZone']?['id'],
        );
        sunrise = todaySunEvents['sunrise'];
        sunset = todaySunEvents['sunset'];
        
        final tomorrowSunEvents = getSunriseSunsetForDate(
          rawWeatherData['forecast']['forecastDays'],
          DateTime.now().add(const Duration(days: 1)),
          timeZoneId: rawWeatherData['forecast']?['timeZone']?['id'],
        );
        tomorrowSunrise = tomorrowSunEvents['sunrise'];
        tomorrowSunset = tomorrowSunEvents['sunset'];
      }
      // --- End Sunrise/Sunset Calculation ---

      final forecastPeriods = _weatherService
          .extractForecast(rawWeatherData)
          .map((data) => ForecastPeriod.fromJson(data))
          .toList();
      final currentConditionsData = _weatherService.extractCurrentConditions(
        rawWeatherData,
      );

      _weatherData = WeatherData(
        sunrise: sunrise,
        sunset: sunset,
        tomorrowSunrise: tomorrowSunrise,
        tomorrowSunset: tomorrowSunset,
        currentConditions: currentConditionsData != null
            ? CurrentConditions.fromJson({
                ...currentConditionsData,
                'aqiCategory': aqiResult?['category'],
              })
            : null,
        forecast: forecastPeriods,
      );
      _hourlyForecast = hourlyData;
      _aqiCategory = aqiResult?['category'];
      _rain24hInches = rainTotals?['inches'];
      _nwsAlerts = alertCollection?.features ?? [];

    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches all weather-related data in parallel for the selected city.
  ///
  /// Notifies listeners at the start and end of the fetch operation
  /// to update the UI with loading, success, or error states.
  Future<void> fetchAllWeatherData() async {
    // Ensure we have a valid selected city
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _weatherService.getCurrentWeather(city: _selectedCity),
        _weatherService.getHourlyForecast(city: _selectedCity),
        _weatherService.fetchAqiCategory(
          latitude: _selectedCity.latitude,
          longitude: _selectedCity.longitude,
          city: _selectedCity,
        ),
        _weatherService.fetch24HourPrecipitationTotal(
          latitude: _selectedCity.latitude,
          longitude: _selectedCity.longitude,
          city: _selectedCity,
        ),
        NwsAlertService.fetchAlertsForCity(_selectedCity),
      ]);

      // Process results
      final rawWeatherData = results[0] as Map<String, dynamic>;
      final hourlyData = results[1] as List<HourlyForecast>;
      final aqiResult = results[2] as Map<String, String?>?;
      final rainTotals = results[3] as Map<String, double>?;
      final alertCollection = results[4] as NwsAlertCollection?;

      // --- Calculate Sunrise/Sunset ---
      DateTime? sunrise;
      DateTime? sunset;
      DateTime? tomorrowSunrise;
      DateTime? tomorrowSunset;
      if (rawWeatherData['forecast']?['forecastDays'] != null) {
        final todaySunEvents = getSunriseSunsetForDate(
          rawWeatherData['forecast']['forecastDays'],
          DateTime.now(),
          timeZoneId: rawWeatherData['forecast']?['timeZone']?['id'],
        );
        sunrise = todaySunEvents['sunrise'];
        sunset = todaySunEvents['sunset'];
        
        final tomorrowSunEvents = getSunriseSunsetForDate(
          rawWeatherData['forecast']['forecastDays'],
          DateTime.now().add(const Duration(days: 1)),
          timeZoneId: rawWeatherData['forecast']?['timeZone']?['id'],
        );
        tomorrowSunrise = tomorrowSunEvents['sunrise'];
        tomorrowSunset = tomorrowSunEvents['sunset'];
      }
      // --- End Sunrise/Sunset Calculation ---

      final forecastPeriods = _weatherService
          .extractForecast(rawWeatherData)
          .map((data) => ForecastPeriod.fromJson(data))
          .toList();
      final currentConditionsData = _weatherService.extractCurrentConditions(
        rawWeatherData,
      );

      _weatherData = WeatherData(
        sunrise: sunrise,
        sunset: sunset,
        tomorrowSunrise: tomorrowSunrise,
        tomorrowSunset: tomorrowSunset,
        currentConditions: currentConditionsData != null
            ? CurrentConditions.fromJson({
                ...currentConditionsData,
                'aqiCategory': aqiResult?['category'],
              })
            : null,
        forecast: forecastPeriods,
      );
      _hourlyForecast = hourlyData;
      _aqiCategory = aqiResult?['category'];
      _rain24hInches = rainTotals?['inches'];
      _nwsAlerts = alertCollection?.features ?? [];

    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force the weather provider to be marked as initialized
  /// This is used as a fallback when location setup fails
  void forceInitialization() {
    if (_locationProvider == null) {
      // Create a dummy location provider reference to mark as initialized
      // This allows the app to continue with default city functionality
      _locationProvider = LocationProvider();
    }
    notifyListeners();
  }
} 