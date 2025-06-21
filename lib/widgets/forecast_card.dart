import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_data.dart';
import '../theme/app_theme.dart';
import 'glass/glass_card.dart';

// Constants for styling and layout
const double kIconSize = 56.0;
const double kSpacingSmall = 6.0;
const double kSpacingStandard = 16.0;
const double kCardPadding = 24.0;

class ForecastCard extends StatelessWidget {
  final ForecastPeriod? dayPeriod;
  final ForecastPeriod? nightPeriod;
  final DateTime date;
  final String iconAsset;
  final bool isNight;

  const ForecastCard({
    super.key,
    required this.dayPeriod,
    required this.nightPeriod,
    required this.date,
    required this.iconAsset,
    this.isNight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 16,
            child: GestureDetector(
              onTap: () => _showDetailDialog(context),
              child: GlassCard(
                useBlur:
                    false, // Use simulated glass for better performance in lists
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 6,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        DateFormat('E').format(date),
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: kSpacingSmall),
                      // High temp: use day period's temperature
                      if (dayPeriod != null)
                        Text(
                          'H: ${dayPeriod!.temperature}°',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      // Low temp: use night period's temperature
                      if (nightPeriod != null)
                        Text(
                          'L: ${nightPeriod!.temperature}°',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMedium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -4,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                iconAsset,
                width: kIconSize,
                height: kIconSize,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SingleChildScrollView(
          child: GlassCard(
            useBlur:
                true, // Use real blur for modal dialogs as they're important UI elements
            child: Padding(
              padding: const EdgeInsets.all(kCardPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Date header with appropriate icon
                  Image.asset(
                    iconAsset,
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: kSpacingStandard),
                  Text(
                    DateFormat('EEEE, MMM d').format(date),
                    style: AppTheme.headingMedium,
                  ),
                  const SizedBox(height: kSpacingStandard),

                  // Day forecast section if available
                  if (dayPeriod != null) _buildDayForecast(context),

                  // Night forecast section if available
                  if (nightPeriod != null) _buildNightForecast(context),

                  // Close button
                  const SizedBox(height: kSpacingStandard),
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

  Widget _buildDayForecast(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wb_sunny, color: AppTheme.iconDay, size: 20),
            const SizedBox(width: 4),
            Text(
              'Daytime',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.iconDay,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'High: ${dayPeriod!.temperature}°F',
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Only show the short forecast in bold, remove detailed/duplicate
        Text(
          dayPeriod!.shortForecast,
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        // --- New detailed fields ---
        if (dayPeriod!.precipProbability != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Precipitation: ${dayPeriod!.precipProbability}%',
              style: AppTheme.bodyMedium,
            ),
          ),
        if (dayPeriod!.windSpeed.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Wind: ${_formatWind(dayPeriod!.windSpeed, dayPeriod!.windDirection)}',
              style: AppTheme.bodyMedium,
            ),
          ),
        if (dayPeriod!.cloudCover != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Cloud Cover: ${dayPeriod!.cloudCover}%',
              style: AppTheme.bodyMedium,
            ),
          ),
        if (dayPeriod!.detailedForecast.isNotEmpty) const SizedBox(height: 8),
        // Thunderstorm probability
        if (dayPeriod!.thunderstormProbability != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Thunderstorm Probability: ${dayPeriod!.thunderstormProbability}%',
              style: AppTheme.bodyMedium,
            ),
          ),
      ],
    );
  }

  Widget _buildNightForecast(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.nights_stay, color: AppTheme.iconNight, size: 20),
            const SizedBox(width: 4),
            Text(
              'Overnight',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.iconNight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Low: ${nightPeriod!.temperature}°F',
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Only show the short forecast in bold, remove detailed/duplicate
        Text(
          nightPeriod!.shortForecast,
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        // --- New detailed fields ---
        if (nightPeriod!.precipProbability != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Precipitation: ${nightPeriod!.precipProbability}%',
              style: AppTheme.bodyMedium,
            ),
          ),
        if (nightPeriod!.windSpeed.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Wind: ${_formatWind(nightPeriod!.windSpeed, nightPeriod!.windDirection)}',
              style: AppTheme.bodyMedium,
            ),
          ),
        if (nightPeriod!.cloudCover != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Cloud Cover: ${nightPeriod!.cloudCover}%',
              style: AppTheme.bodyMedium,
            ),
          ),
        // Thunderstorm probability
        if (nightPeriod!.thunderstormProbability != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Thunderstorm Probability: ${nightPeriod!.thunderstormProbability}%',
              style: AppTheme.bodyMedium,
            ),
          ),
      ],
    );
  }

  String _formatWind(String windSpeed, String windDirection) {
    // Try to parse windSpeed as double (assume it's in mph from API)
    double? speed = double.tryParse(windSpeed);
    String speedStr = speed != null
        ? '${speed.toStringAsFixed(0)} mph'
        : windSpeed;
    String dirStr = '';
    int? deg = int.tryParse(windDirection);
    if (deg != null) {
      dirStr = ' ${_degreesToCompass(deg)}';
    }
    return speedStr + dirStr;
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
