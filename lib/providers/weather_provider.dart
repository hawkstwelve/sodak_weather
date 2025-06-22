import 'package:flutter/material.dart';
import '../models/sd_city.dart';
import '../models/weather_data.dart';
import '../models/hourly_forecast.dart';
import '../models/nws_alert_model.dart';
import '../services/weather_service.dart';
import '../services/nws_alert_service.dart';
import '../utils/sun_utils.dart';
import 'location_provider.dart';

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
    // Don't fetch initial weather data here - wait for location provider to be set
    // fetchAllWeatherData();
  }

  /// Set the location provider reference
  Future<void> setLocationProvider(LocationProvider locationProvider) async {
    _locationProvider = locationProvider;
    // Wait for location provider to finish initializing
    await _locationProvider!.initializationDone;
    // After setting the location provider, check if we should use cached location
    await _initializeWithCachedLocation();
  }

  /// Initialize with cached location if available, otherwise use default city
  Future<void> _initializeWithCachedLocation() async {
    if (_locationProvider == null) return;
    
    // Check if there's cached location
    if (_locationProvider!.hasLocation && _locationProvider!.isUsingCachedLocation) {
      _isUsingLocation = true;
      await fetchAllWeatherDataForCoordinates(
        _locationProvider!.currentLocation!.latitude,
        _locationProvider!.currentLocation!.longitude,
      );
    } else {
      // Fetch initial weather data for default city
      fetchAllWeatherData();
    }
  }

  /// Sets the selected city and fetches new weather data for it.
  void setSelectedCity(SDCity city) {
    if (_selectedCity.name != city.name || _isUsingLocation) {
      _selectedCity = city;
      _isUsingLocation = false;
      fetchAllWeatherData();
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
      await fetchAllWeatherDataForCoordinates(
        _locationProvider!.currentLocation!.latitude,
        _locationProvider!.currentLocation!.longitude,
      );
      return true;
    } else {
      _errorMessage = _locationProvider!.errorMessage ?? 'Unable to refresh location';
      notifyListeners();
      return false;
    }
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
} 