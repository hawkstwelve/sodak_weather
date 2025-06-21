class WeatherHistoryHour {
  final DateTime time;
  final double? precipitationMm;

  WeatherHistoryHour({
    required this.time,
    this.precipitationMm,
  });

  factory WeatherHistoryHour.fromJson(Map<String, dynamic> json) {
    return WeatherHistoryHour(
      time: DateTime.parse(json['dateTime']),
      precipitationMm: json['qpf'] != null && json['qpf']['quantity'] != null
          ? (json['qpf']['quantity'] as num).toDouble()
          : null,
    );
  }
}

class WeatherData {
  final CurrentConditions? currentConditions;
  final List<ForecastPeriod> forecast;
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? tomorrowSunrise;
  final DateTime? tomorrowSunset;

  WeatherData({
    this.currentConditions,
    required this.forecast,
    this.sunrise,
    this.sunset,
    this.tomorrowSunrise,
    this.tomorrowSunset,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      currentConditions: json['currentConditions'] != null
          ? CurrentConditions.fromJson(json['currentConditions'])
          : null,
      forecast: (json['forecast'] as List)
          .map((period) => ForecastPeriod.fromJson(period))
          .toList(),
    );
  }
}

class CurrentConditions {
  final double? temperature;
  final double? apparentTemperature;
  final double? dewpoint;
  final int? humidity;
  final double? windSpeed;
  final double? windGust;
  final int? windDirection;
  final double? pressure;
  final double? visibility;
  final String? textDescription;
  final DateTime? timestamp;
  final int? uvIndex;
  final double? precip1h;
  final String? precip1hUnit;
  final int? aqi;

  CurrentConditions({
    this.temperature,
    this.apparentTemperature,
    this.dewpoint,
    this.humidity,
    this.windSpeed,
    this.windGust,
    this.windDirection,
    this.pressure,
    this.visibility,
    this.textDescription,
    this.timestamp,
    this.uvIndex,
    this.precip1h,
    this.precip1hUnit,
    this.aqi,
  });

  factory CurrentConditions.fromJson(Map<String, dynamic> json) {
    return CurrentConditions(
      temperature: json['temperature']?.toDouble(),
      apparentTemperature: json['apparentTemperature']?.toDouble(),
      dewpoint: json['dewpoint']?.toDouble(),
      humidity: json['humidity']?.toInt(),
      windSpeed: json['windSpeed']?.toDouble(),
      windGust: json['windGust']?.toDouble(),
      windDirection: json['windDirection']?.toInt(),
      pressure: json['pressure']?.toDouble(),
      visibility: json['visibility']?.toDouble(),
      textDescription: json['textDescription'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
      uvIndex: json['uvIndex'] as int?,
      precip1h: (json['precip1h'] as num?)?.toDouble(),
      precip1hUnit: json['precip1hUnit'] as String?,
      aqi: json['aqi'] as int?,
    );
  }

  // Remove conversion for temperatureFahrenheit, just return the value for imperial units
  double? get temperatureFahrenheit {
    return temperature;
  }

  // Convert meters per second to miles per hour
  double? get windSpeedMph {
    if (windSpeed == null) return null;
    return windSpeed! * 2.237;
  }

  // Convert meters to miles
  double? get visibilityMiles {
    if (visibility == null) return null;
    return visibility! * 0.000621371;
  }
}

class ForecastPeriod {
  final String name;
  final int temperature;
  final String temperatureUnit;
  final String windSpeed;
  final String windDirection;
  final String shortForecast;
  final String detailedForecast;
  final String icon;
  final DateTime startTime;
  final DateTime endTime;
  final bool isDaytime;
  final int? precipProbability;
  final int? cloudCover;
  final DateTime? sunriseTime;
  final DateTime? sunsetTime;
  final int? thunderstormProbability;

  ForecastPeriod({
    required this.name,
    required this.temperature,
    required this.temperatureUnit,
    required this.windSpeed,
    required this.windDirection,
    required this.shortForecast,
    required this.detailedForecast,
    required this.icon,
    required this.startTime,
    required this.endTime,
    required this.isDaytime,
    this.precipProbability,
    this.cloudCover,
    this.sunriseTime,
    this.sunsetTime,
    this.thunderstormProbability,
  });

  factory ForecastPeriod.fromJson(Map<String, dynamic> json) {
    return ForecastPeriod(
      name: json['name'],
      temperature: (json['temperature'] is int)
          ? json['temperature']
          : (json['temperature'] is double)
              ? (json['temperature'] as double).round()
              : 0,
      temperatureUnit: json['temperatureUnit']?.toString() ?? '',
      windSpeed: json['windSpeed']?.toString() ?? '',
      windDirection: json['windDirection']?.toString() ?? '',
      shortForecast: json['shortForecast']?.toString() ?? '',
      detailedForecast: json['detailedForecast']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      isDaytime: json['isDaytime'] is bool ? json['isDaytime'] : true,
      precipProbability: json['precipProbability'] is int
          ? json['precipProbability']
          : (json['precipProbability'] is double)
              ? (json['precipProbability'] as double).round()
              : null,
      cloudCover: json['cloudCover'] is int
          ? json['cloudCover']
          : (json['cloudCover'] is double)
              ? (json['cloudCover'] as double).round()
              : null,
      sunriseTime: json['sunEvents'] != null && json['sunEvents']['sunriseTime'] != null
          ? DateTime.tryParse(json['sunEvents']['sunriseTime'])
          : null,
      sunsetTime: json['sunEvents'] != null && json['sunEvents']['sunsetTime'] != null
          ? DateTime.tryParse(json['sunEvents']['sunsetTime'])
          : null,
      thunderstormProbability: json['thunderstormProbability'] is int
          ? json['thunderstormProbability']
          : (json['thunderstormProbability'] is double)
              ? (json['thunderstormProbability'] as double).round()
              : null,
    );
  }
}

// Utility function to parse a list of WeatherHistoryHour from API response
List<WeatherHistoryHour> parseWeatherHistoryHours(List<dynamic> jsonList) {
  return jsonList
      .map((item) => WeatherHistoryHour.fromJson(item))
      .toList();
}