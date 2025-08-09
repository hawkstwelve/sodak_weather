import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/ui_constants.dart';
import '../../models/hourly_forecast.dart';
import '../../theme/app_theme.dart';
import '../../utils/hour_utils.dart';
import '../../utils/weather_utils.dart';
import '../glass/glass_card.dart';

/// Shows a modal dialog with detailed information for a single hourly forecast.
void showHourlyForecastDetailDialog({
  required BuildContext context,
  required HourlyForecast forecast,
  DateTime? sunrise,
  DateTime? sunset,
  DateTime? tomorrowSunrise,
  DateTime? tomorrowSunset,
}) {
  final bool isNight = isNightHourMultiDay(
    forecast.time.toLocal(),
    {'sunrise': sunrise, 'sunset': sunset},
    {'sunrise': tomorrowSunrise, 'sunset': tomorrowSunset},
  );
  final String iconAsset = WeatherUtils.getWeatherIconAsset(
    forecast.shortForecast,
    isNight: isNight,
  );

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SingleChildScrollView(
        child: GlassCard(
          useBlur: true,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Time header with appropriate icon
                Image.asset(
                  iconAsset,
                  width: UIConstants.iconSizeLarge,
                  height: UIConstants.iconSizeLarge,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: UIConstants.spacingXLarge),
                Text(
                  DateFormat('EEEE, MMM d').format(forecast.time.toLocal()),
                  style: AppTheme.headingMedium,
                ),
                Text(
                  DateFormat('h:mm a').format(forecast.time.toLocal()),
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: UIConstants.spacingXLarge),

                _buildTemperatureSection(forecast),

                const SizedBox(height: UIConstants.spacingXLarge),
                AutoSizeText(
                  forecast.shortForecast,
                  style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  minFontSize: 14,
                ),

                const SizedBox(height: UIConstants.spacingXXXLarge),
                _buildDetailedWeatherInfo(forecast),

                const SizedBox(height: UIConstants.spacingXLarge),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: AppTheme.textBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildTemperatureSection(HourlyForecast forecast) {
  return Column(
    children: [
      Text(
        '${forecast.temperature.round()}°F',
        style: AppTheme.headingLarge.copyWith(fontWeight: FontWeight.bold),
      ),
      if (forecast.feelsLikeTemperature != null) ...[
        const SizedBox(height: UIConstants.spacingSmall),
        Text(
          'Feels like ${forecast.feelsLikeTemperature!.round()}°F',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMedium),
        ),
      ],
    ],
  );
}

Widget _buildDetailedWeatherInfo(HourlyForecast forecast) {
  final bool hasNoDetails = forecast.precipProbability == null &&
      forecast.precipAmount == null &&
      forecast.thunderstormProbability == null &&
      forecast.windSpeed == null &&
      forecast.relativeHumidity == null &&
      forecast.dewPoint == null &&
      forecast.cloudCover == null;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (forecast.precipProbability != null || forecast.precipAmount != null)
        _buildInfoRow(Icons.water_drop, 'Precipitation', _formatPrecipitation(forecast)),
      if (forecast.thunderstormProbability != null && forecast.thunderstormProbability! > 0)
        _buildInfoRow(Icons.thunderstorm, 'Thunderstorm', '${forecast.thunderstormProbability}% chance'),
      if (forecast.windSpeed != null)
        _buildInfoRow(Icons.air, 'Wind', _formatWind(forecast)),
      if (forecast.relativeHumidity != null)
        _buildInfoRow(Icons.opacity, 'Humidity', '${forecast.relativeHumidity}%'),
      if (forecast.dewPoint != null)
        _buildInfoRow(Icons.thermostat, 'Dew Point', '${forecast.dewPoint!.round()}°F'),
      if (forecast.cloudCover != null)
        _buildInfoRow(Icons.cloud, 'Cloud Cover', '${forecast.cloudCover}%'),
      if (hasNoDetails)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Detailed weather information not available for this hour.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textMedium,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
    ],
  );
}

Widget _buildInfoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Icon(icon, color: AppTheme.textLight, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMedium),
          ),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

String _formatPrecipitation(HourlyForecast forecast) {
  String result = '';
  if (forecast.precipProbability != null) {
    result += '${forecast.precipProbability}% chance of';
    if (forecast.precipType != null) {
      result += ' ${forecast.precipType!.toLowerCase()}';
    }
  }
  return result.isEmpty ? 'None' : result;
}

String _formatWind(HourlyForecast forecast) {
  String result = '';
  if (forecast.windDirectionCardinal != null) {
    result += _formatCardinalDirection(forecast.windDirectionCardinal!);
  } else if (forecast.windDirection != null) {
    result += _degreesToCompass(forecast.windDirection!.round());
  }
  if (forecast.windSpeed != null) {
    if (result.isNotEmpty) result += ' ';
    double speed = forecast.windSpeed!;
    String unit = 'mph';
    if (forecast.windSpeedUnit == 'KILOMETERS_PER_HOUR') {
      speed = speed * 0.621371;
    }
    result += '${speed.round()} $unit';
  }
  if (forecast.windGust != null) {
    if (result.isNotEmpty) result += ' • ';
    double gust = forecast.windGust!;
    String unit = 'mph';
    if (forecast.windGustUnit == 'KILOMETERS_PER_HOUR') {
      gust = gust * 0.621371;
    }
    result += 'G ${gust.round()} $unit';
  }
  return result.isEmpty ? 'Calm' : result;
}

String _formatCardinalDirection(String cardinal) {
  const Map<String, String> directions = {
    'NORTH': 'N',
    'NORTH_NORTHEAST': 'NNE',
    'NORTHEAST': 'NE',
    'EAST_NORTHEAST': 'ENE',
    'EAST': 'E',
    'EAST_SOUTHEAST': 'ESE',
    'SOUTHEAST': 'SE',
    'SOUTH_SOUTHEAST': 'SSE',
    'SOUTH': 'S',
    'SOUTH_SOUTHWEST': 'SSW',
    'SOUTHWEST': 'SW',
    'WEST_SOUTHWEST': 'WSW',
    'WEST': 'W',
    'WEST_NORTHWEST': 'WNW',
    'NORTHWEST': 'NW',
    'NORTH_NORTHWEST': 'NNW',
  };
  return directions[cardinal] ?? cardinal;
}

String _degreesToCompass(int degrees) {
  const List<String> directions = [
    'N',
    'NNE',
    'NE',
    'ENE',
    'E',
    'ESE',
    'SE',
    'SSE',
    'S',
    'SSW',
    'SW',
    'WSW',
    'W',
    'WNW',
    'NW',
    'NNW',
    'N',
  ];
  final int idx = ((degrees % 360) / 22.5).round();
  return directions[idx];
}


