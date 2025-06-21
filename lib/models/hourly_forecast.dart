class HourlyForecast {
  final DateTime time;
  final double temperature;
  final String temperatureUnit;
  final String icon;
  final String shortForecast;
  final int? precipProbability; // Chance of precipitation (0-100)
  final double? precipAmount; // Amount of precipitation
  final String? precipUnit; // Unit of precipitation measurement

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.temperatureUnit,
    required this.icon,
    required this.shortForecast,
    this.precipProbability,
    this.precipAmount,
    this.precipUnit,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    // Extract precipitation data
    final precipitation = json['precipitation'];
    final precipProbability = precipitation?['probability']?['percent'] as int?;
    final precipQpf = precipitation?['qpf'];
    final precipAmount = precipQpf?['quantity']?.toDouble();
    final precipUnit = precipQpf?['unit'] as String?;

    return HourlyForecast(
      time: DateTime.parse(json['interval']['startTime']),
      temperature: json['temperature']?['degrees']?.toDouble() ?? 0.0,
      temperatureUnit: json['temperature']?['unit']?.toString() ?? 'F',
      icon: json['weatherCondition']?['iconBaseUri']?.toString() ?? '',
      shortForecast: json['weatherCondition']?['description']?['text']?.toString() ?? '',
      precipProbability: precipProbability,
      precipAmount: precipAmount,
      precipUnit: precipUnit,
    );
  }
}
