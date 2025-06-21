import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/weather_utils.dart';
import '../utils/hour_utils.dart';
import '../models/hourly_forecast.dart';
import '../theme/app_theme.dart';
import 'glass/glass_card.dart';

class HourlyForecastCard extends StatelessWidget {
  final HourlyForecast forecast;
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? tomorrowSunrise;
  final DateTime? tomorrowSunset;
  final bool useBlur; // Add parameter for conditional blur effect

  const HourlyForecastCard({
    super.key,
    required this.forecast,
    this.sunrise,
    this.sunset,
    this.tomorrowSunrise,
    this.tomorrowSunset,
    this.useBlur =
        false, // Default to false for better performance in scrollable lists
  });

  @override
  Widget build(BuildContext context) {
    final bool isNight = isNightHourMultiDay(
      forecast.time.toLocal(),
      {'sunrise': sunrise, 'sunset': sunset},
      {'sunrise': tomorrowSunrise, 'sunset': tomorrowSunset},
    );
    final iconAsset = WeatherUtils.getWeatherIconAsset(
      forecast.shortForecast,
      isNight: isNight,
    );

    return SizedBox(
      width: 80,
      height: 140,
      child: GlassCard(
        useBlur: useBlur, // Pass the parameter to GlassCard
        opacity: 0.2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('ha').format(forecast.time.toLocal()),
                style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Image.asset(iconAsset, width: 32, height: 32),
              const SizedBox(height: 4),
              Text(
                '${forecast.temperature.round()}°F',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 32,
                child: Center(
                  child: Text(
                    forecast.shortForecast,
                    style: AppTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
