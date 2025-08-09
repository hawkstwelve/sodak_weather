import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/ui_constants.dart';
import '../../models/weather_data.dart';
import '../../theme/app_theme.dart';
import '../glass/glass_card.dart';

/// Shows a modal dialog with detailed information for a single day's forecast.
void showDailyForecastDetailDialog({
  required BuildContext context,
  required DateTime date,
  required ForecastPeriod? dayPeriod,
  required ForecastPeriod? nightPeriod,
  required String iconAsset,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SingleChildScrollView(
        child: GlassCard(
          useBlur: true,
          child: Padding(
            padding: const EdgeInsets.all(UIConstants.spacingXXXLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  iconAsset,
                  width: UIConstants.iconSizeLarge,
                  height: UIConstants.iconSizeLarge,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: UIConstants.spacingXLarge),
                Text(
                  DateFormat('EEEE, MMM d').format(date),
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: UIConstants.spacingXLarge),
                if (dayPeriod != null) _buildDayForecast(dayPeriod),
                if (nightPeriod != null) _buildNightForecast(nightPeriod),
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

Widget _buildDayForecast(ForecastPeriod period) {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wb_sunny, color: AppTheme.iconDay, size: 20),
          const SizedBox(width: UIConstants.spacingSmall),
          Text(
            'Daytime',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.iconDay,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: UIConstants.spacingStandard),
      Text(
        'High: ${period.temperature}°F',
        style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: UIConstants.spacingStandard),
      Text(
        period.shortForecast,
        style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      if (period.precipProbability != null)
        Padding(
          padding: const EdgeInsets.only(top: UIConstants.spacingStandard),
          child: Text(
            'Precipitation: ${period.precipProbability}%',
            style: AppTheme.bodyMedium,
          ),
        ),
      if (period.windSpeed.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
          child: Text(
            'Wind: ${_formatWind(period.windSpeed, period.windDirection, period.windGust)}',
            style: AppTheme.bodyMedium,
          ),
        ),
      if (period.relativeHumidity != null)
        Padding(
          padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
          child: Text(
            'Humidity: ${period.relativeHumidity}%',
            style: AppTheme.bodyMedium,
          ),
        ),
      if (period.cloudCover != null)
        Padding(
          padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
          child: Text(
            'Cloud Cover: ${period.cloudCover}%',
            style: AppTheme.bodyMedium,
          ),
        ),
      if (period.thunderstormProbability != null)
        Padding(
          padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
          child: Text(
            'Thunderstorm Probability: ${period.thunderstormProbability}%',
            style: AppTheme.bodyMedium,
          ),
        ),
    ],
  );
}

Widget _buildNightForecast(ForecastPeriod period) {
  return Column(
    children: [
      const SizedBox(height: UIConstants.spacingXLarge),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.nights_stay, color: AppTheme.iconNight, size: 20),
          const SizedBox(width: UIConstants.spacingSmall),
          Text(
            'Overnight',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.iconNight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: UIConstants.spacingStandard),
      Text(
        'Low: ${period.temperature}°F',
        style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: UIConstants.spacingStandard),
      Text(
        period.shortForecast,
        style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      if (period.precipProbability != null)
        Padding(
          padding: const EdgeInsets.only(top: UIConstants.spacingStandard),
          child: Text(
            'Precipitation: ${period.precipProbability}%',
            style: AppTheme.bodyMedium,
          ),
        ),
      if (period.windSpeed.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
          child: Text(
            'Wind: ${_formatWind(period.windSpeed, period.windDirection, period.windGust)}',
            style: AppTheme.bodyMedium,
          ),
        ),
      if (period.relativeHumidity != null)
        Padding(
          padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
          child: Text(
            'Humidity: ${period.relativeHumidity}%',
            style: AppTheme.bodyMedium,
          ),
        ),
      if (period.cloudCover != null)
        Padding(
          padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
          child: Text(
            'Cloud Cover: ${period.cloudCover}%',
            style: AppTheme.bodyMedium,
          ),
        ),
      if (period.thunderstormProbability != null)
        Padding(
          padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
          child: Text(
            'Thunderstorm Probability: ${period.thunderstormProbability}%',
            style: AppTheme.bodyMedium,
          ),
        ),
    ],
  );
}

String _formatWind(String windSpeed, String windDirection, double? windGust) {
  final double? parsedSpeed = double.tryParse(windSpeed);
  final String speedStr = parsedSpeed != null ? '${parsedSpeed.toStringAsFixed(0)} mph' : windSpeed;
  String dirStr = '';
  final int? deg = int.tryParse(windDirection);
  if (deg != null) {
    dirStr = _degreesToCompass(deg);
  }
  String result = '';
  if (dirStr.isNotEmpty) {
    result += dirStr;
  }
  if (speedStr.isNotEmpty) {
    result += result.isNotEmpty ? ' ' : '';
    result += speedStr;
  }
  if (windGust != null) {
    result += result.isNotEmpty ? ' • ' : '';
    result += 'G ${windGust.toStringAsFixed(0)} mph';
  }
  return result.isNotEmpty ? result : 'Calm';
}

String _degreesToCompass(int degrees) {
  const List<String> directions = [
    'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW', 'N'
  ];
  final int idx = ((degrees % 360) / 22.5).round();
  return directions[idx];
}


