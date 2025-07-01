class HourlyForecast {
  final DateTime time;
  final double temperature;
  final String temperatureUnit;
  final String icon;
  final String shortForecast;
  final int? precipProbability; // Chance of precipitation (0-100)
  final double? precipAmount; // Amount of precipitation
  final String? precipUnit; // Unit of precipitation measurement
  final String? precipType; // Type of precipitation (RAIN, SNOW, etc.)
  
  // Additional fields for detailed view
  final double? feelsLikeTemperature;
  final double? dewPoint;
  final int? relativeHumidity;
  final int? thunderstormProbability;
  final int? cloudCover;
  final double? windSpeed;
  final String? windSpeedUnit;
  final double? windGust;
  final String? windGustUnit;
  final double? windDirection;
  final String? windDirectionCardinal;
  final bool? isDaytime;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.temperatureUnit,
    required this.icon,
    required this.shortForecast,
    this.precipProbability,
    this.precipAmount,
    this.precipUnit,
    this.precipType,
    this.feelsLikeTemperature,
    this.dewPoint,
    this.relativeHumidity,
    this.thunderstormProbability,
    this.cloudCover,
    this.windSpeed,
    this.windSpeedUnit,
    this.windGust,
    this.windGustUnit,
    this.windDirection,
    this.windDirectionCardinal,
    this.isDaytime,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    // Extract precipitation data
    final precipitation = json['precipitation'];
    final precipProbability = precipitation?['probability']?['percent'] as int?;
    final precipType = precipitation?['probability']?['type'] as String?;
    final precipQpf = precipitation?['qpf'];
    final precipAmount = precipQpf?['quantity']?.toDouble();
    final precipUnit = precipQpf?['unit'] as String?;

    // Extract wind data
    final wind = json['wind'];
    final windSpeed = wind?['speed']?['value']?.toDouble();
    final windSpeedUnit = wind?['speed']?['unit'] as String?;
    final windGust = wind?['gust']?['value']?.toDouble();
    final windGustUnit = wind?['gust']?['unit'] as String?;
    final windDirection = wind?['direction']?['degrees']?.toDouble();
    final windDirectionCardinal = wind?['direction']?['cardinal'] as String?;

    return HourlyForecast(
      time: DateTime.parse(json['interval']['startTime']),
      temperature: json['temperature']?['degrees']?.toDouble() ?? 0.0,
      temperatureUnit: json['temperature']?['unit']?.toString() ?? 'F',
      icon: json['weatherCondition']?['iconBaseUri']?.toString() ?? '',
      shortForecast: json['weatherCondition']?['description']?['text']?.toString() ?? '',
      precipProbability: precipProbability,
      precipAmount: precipAmount,
      precipUnit: precipUnit,
      precipType: precipType,
      feelsLikeTemperature: json['feelsLikeTemperature']?['degrees']?.toDouble(),
      dewPoint: json['dewPoint']?['degrees']?.toDouble(),
      relativeHumidity: json['relativeHumidity'] as int?,
      thunderstormProbability: json['thunderstormProbability'] as int?,
      cloudCover: json['cloudCover'] as int?,
      windSpeed: windSpeed,
      windSpeedUnit: windSpeedUnit,
      windGust: windGust,
      windGustUnit: windGustUnit,
      windDirection: windDirection,
      windDirectionCardinal: windDirectionCardinal,
      isDaytime: json['isDaytime'] as bool?,
    );
  }
}
