import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_data.dart';
// import '../theme/app_theme.dart';
import 'glass/glass_card.dart';
import '../constants/ui_constants.dart';

// Constants for styling and layout
const double kIconSize = UIConstants.iconSizeLarge;
const double kSpacingSmall = UIConstants.spacingMedium;
const double kSpacingStandard = UIConstants.spacingXLarge;
const double kCardPadding = UIConstants.spacingXXXLarge;

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
      height: UIConstants.cardHeightMedium,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: UIConstants.spacingXLarge,
            child: GestureDetector(
              onTap: () => _showDetailDialog(context),
                             child: GlassCard(
                 priority: GlassCardPriority.standard,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: UIConstants.spacingMedium,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: UIConstants.spacingXXXLarge),
                      Text(DateFormat('E').format(date), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: kSpacingSmall),
                      // High temp: use day period's temperature
                      if (dayPeriod != null)
                        Text('H: ${dayPeriod!.temperature}°', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface), textAlign: TextAlign.center),
                      // Low temp: use night period's temperature
                      if (nightPeriod != null)
                        Text('L: ${nightPeriod!.temperature}°', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -UIConstants.spacingSmall,
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
      barrierColor: Colors.transparent,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Simple dark overlay for background - this will definitely work
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.8), // Adjust this value: 0.0 = transparent, 1.0 = solid black
                ),
              ),
            ),
            // Modal content
            Center(
              child: GestureDetector(
                onTap: () {}, // Prevent tap from closing modal
                child: GlassCard(
                  priority: GlassCardPriority.prominent,
                  child: Padding(
                    padding: const EdgeInsets.all(kCardPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Date header with appropriate icon
                        Image.asset(
                          iconAsset,
                          width: UIConstants.iconSizeLarge,
                          height: UIConstants.iconSizeLarge,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: UIConstants.spacingStandard),
                        Text(DateFormat('EEEE, MMM d').format(date), style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: kSpacingStandard),

                        // Day forecast section if available
                        if (dayPeriod != null) _buildDayForecast(context),

                        // Night forecast section if available
                        if (nightPeriod != null) _buildNightForecast(context),

                        // Close button
                        const SizedBox(height: kSpacingStandard),
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: Builder(builder: (context) => Text('Close', style: TextStyle(color: Theme.of(context).colorScheme.primary)))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
            Icon(Icons.wb_sunny, color: Theme.of(context).colorScheme.secondary, size: 20),
            const SizedBox(width: UIConstants.spacingSmall),
            Text('Daytime', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: UIConstants.spacingStandard),
        Text('High: ${dayPeriod!.temperature}°F', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: UIConstants.spacingStandard),
        // Only show the short forecast in bold, remove detailed/duplicate
        Text(dayPeriod!.shortForecast, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        // --- New detailed fields ---
        if (dayPeriod!.precipProbability != null)
          Padding(
            padding: const EdgeInsets.only(top: UIConstants.spacingStandard),
            child: Text('Precipitation: ${dayPeriod!.precipProbability}%', style: Theme.of(context).textTheme.bodyMedium),
          ),
        if (dayPeriod!.windSpeed.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
            child: Text('Wind: ${_formatWind(dayPeriod!.windSpeed, dayPeriod!.windDirection, dayPeriod!.windGust)}', style: Theme.of(context).textTheme.bodyMedium),
          ),
        if (dayPeriod!.relativeHumidity != null)
          Padding(
            padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
            child: Text('Humidity: ${dayPeriod!.relativeHumidity}%', style: Theme.of(context).textTheme.bodyMedium),
          ),
        if (dayPeriod!.cloudCover != null)
          Padding(
            padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
            child: Text('Cloud Cover: ${dayPeriod!.cloudCover}%', style: Theme.of(context).textTheme.bodyMedium),
          ),
        // Thunderstorm probability
        if (dayPeriod!.thunderstormProbability != null)
          Padding(
            padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
            child: Text('Thunderstorm Probability: ${dayPeriod!.thunderstormProbability}%', style: Theme.of(context).textTheme.bodyMedium),
          ),
      ],
    );
  }

  Widget _buildNightForecast(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: UIConstants.spacingXLarge),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nights_stay, color: Theme.of(context).colorScheme.tertiary, size: 20),
            const SizedBox(width: UIConstants.spacingSmall),
            Text('Overnight', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: UIConstants.spacingStandard),
        Text('Low: ${nightPeriod!.temperature}°F', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: UIConstants.spacingStandard),
        // Only show the short forecast in bold, remove detailed/duplicate
        Text(nightPeriod!.shortForecast, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        // --- New detailed fields ---
        if (nightPeriod!.precipProbability != null)
          Padding(
            padding: const EdgeInsets.only(top: UIConstants.spacingStandard),
            child: Text('Precipitation: ${nightPeriod!.precipProbability}%', style: Theme.of(context).textTheme.bodyMedium),
          ),
        if (nightPeriod!.windSpeed.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
            child: Text('Wind: ${_formatWind(nightPeriod!.windSpeed, nightPeriod!.windDirection, nightPeriod!.windGust)}', style: Theme.of(context).textTheme.bodyMedium),
          ),
        if (nightPeriod!.relativeHumidity != null)
          Padding(
            padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
            child: Text('Humidity: ${nightPeriod!.relativeHumidity}%', style: Theme.of(context).textTheme.bodyMedium),
          ),
        if (nightPeriod!.cloudCover != null)
          Padding(
            padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
            child: Text('Cloud Cover: ${nightPeriod!.cloudCover}%', style: Theme.of(context).textTheme.bodyMedium),
          ),
        // Thunderstorm probability
        if (nightPeriod!.thunderstormProbability != null)
          Padding(
            padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
            child: Text('Thunderstorm Probability: ${nightPeriod!.thunderstormProbability}%', style: Theme.of(context).textTheme.bodyMedium),
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
