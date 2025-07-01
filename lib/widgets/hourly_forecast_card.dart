import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/weather_utils.dart';
import '../utils/hour_utils.dart';
import '../models/hourly_forecast.dart';
import '../theme/app_theme.dart';
import 'glass/glass_card.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../constants/ui_constants.dart';

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
      height: UIConstants.cardHeightMedium,
      child: GestureDetector(
        onTap: () => _showDetailDialog(context),
        child: GlassCard(
          useBlur: useBlur, // Pass the parameter to GlassCard
          opacity: UIConstants.opacityVeryLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('ha').format(forecast.time.toLocal()),
                  style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: UIConstants.spacingSmall),
                Image.asset(iconAsset, width: UIConstants.iconSizeHourlyForecast, height: UIConstants.iconSizeHourlyForecast),
                const SizedBox(height: UIConstants.spacingSmall),
                Text(
                  '${forecast.temperature.round()}°F',
                  style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: UIConstants.spacingSmall),
                SizedBox(
                  height: UIConstants.spacingHuge,
                  child: Center(
                    child: AutoSizeText(
                      forecast.shortForecast,
                      style: AppTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      minFontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    final bool isNight = isNightHourMultiDay(
      forecast.time.toLocal(),
      {'sunrise': sunrise, 'sunset': sunset},
      {'sunrise': tomorrowSunrise, 'sunset': tomorrowSunset},
    );
    final iconAsset = WeatherUtils.getWeatherIconAsset(
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
            useBlur: true, // Use real blur for modal dialogs
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

                  // Main temperature section
                  _buildTemperatureSection(),

                  // Weather description
                  const SizedBox(height: UIConstants.spacingXLarge),
                  Text(
                    forecast.shortForecast,
                    style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: UIConstants.spacingXXXLarge),

                  // Detailed weather information
                  _buildDetailedWeatherInfo(),

                  // Close button
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

  Widget _buildTemperatureSection() {
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

  Widget _buildDetailedWeatherInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Precipitation section
        if (forecast.precipProbability != null || forecast.precipAmount != null)
          _buildInfoRow(
            Icons.water_drop,
            'Precipitation',
            _formatPrecipitation(),
          ),

        // Thunderstorm probability
        if (forecast.thunderstormProbability != null && forecast.thunderstormProbability! > 0)
          _buildInfoRow(
            Icons.thunderstorm,
            'Thunderstorm',
            '${forecast.thunderstormProbability}% chance',
          ),

        // Wind section
        if (forecast.windSpeed != null)
          _buildInfoRow(
            Icons.air,
            'Wind',
            _formatWind(),
          ),

        // Humidity
        if (forecast.relativeHumidity != null)
          _buildInfoRow(
            Icons.opacity,
            'Humidity',
            '${forecast.relativeHumidity}%',
          ),

        // Dew point
        if (forecast.dewPoint != null)
          _buildInfoRow(
            Icons.thermostat,
            'Dew Point',
            '${forecast.dewPoint!.round()}°F',
          ),

        // Cloud cover
        if (forecast.cloudCover != null)
          _buildInfoRow(
            Icons.cloud,
            'Cloud Cover',
            '${forecast.cloudCover}%',
          ),

        // Show a message if no detailed data is available
        if (forecast.precipProbability == null && 
            forecast.precipAmount == null &&
            forecast.thunderstormProbability == null &&
            forecast.windSpeed == null &&
            forecast.relativeHumidity == null &&
            forecast.dewPoint == null &&
            forecast.cloudCover == null)
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
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textMedium,
              ),
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrecipitation() {
    String result = '';
    if (forecast.precipProbability != null) {
      result += '${forecast.precipProbability}% chance of';
      if (forecast.precipType != null) {
        result += ' ${forecast.precipType!.toLowerCase()}';
      }
    }
    return result.isEmpty ? 'None' : result;
  }

  String _formatWind() {
    String result = '';
    
    // Wind direction (now first)
    if (forecast.windDirectionCardinal != null) {
      result += _formatCardinalDirection(forecast.windDirectionCardinal!);
    } else if (forecast.windDirection != null) {
      result += _degreesToCompass(forecast.windDirection!.round());
    }

    // Wind speed (now second)
    if (forecast.windSpeed != null) {
      if (result.isNotEmpty) result += ' ';
      double speed = forecast.windSpeed!;
      String unit = 'mph';
      
      // Convert km/h to mph if needed
      if (forecast.windSpeedUnit == 'KILOMETERS_PER_HOUR') {
        speed = speed * 0.621371; // Convert km/h to mph
      }
      result += '${speed.round()} $unit';
    }

    // Wind gust
    if (forecast.windGust != null) {
      if (result.isNotEmpty) result += ' • ';
      double gust = forecast.windGust!;
      String unit = 'mph';
      
      // Convert km/h to mph if needed
      if (forecast.windGustUnit == 'KILOMETERS_PER_HOUR') {
        gust = gust * 0.621371; // Convert km/h to mph
      }
      result += 'G ${gust.round()} $unit';
    }

    return result.isEmpty ? 'Calm' : result;
  }

  String _formatCardinalDirection(String cardinal) {
    // Convert Google Weather API cardinal directions to readable format
    final directions = {
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
    const directions = [
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
    int idx = ((degrees % 360) / 22.5).round();
    return directions[idx];
  }
}
