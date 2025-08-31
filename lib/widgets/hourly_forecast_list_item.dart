import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/ui_constants.dart';
import '../models/hourly_forecast.dart';
// import '../theme/app_theme.dart';
import '../utils/hour_utils.dart';
import '../utils/weather_utils.dart';
import 'dialogs/hourly_forecast_detail_dialog.dart';


class HourlyForecastListItem extends StatelessWidget {
  final HourlyForecast forecast;
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? tomorrowSunrise;
  final DateTime? tomorrowSunset;

  const HourlyForecastListItem({
    super.key,
    required this.forecast,
    this.sunrise,
    this.sunset,
    this.tomorrowSunrise,
    this.tomorrowSunset,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNight = isNightHourMultiDay(
      forecast.time.toLocal(),
      {'sunrise': sunrise, 'sunset': sunset},
      {'sunrise': tomorrowSunrise, 'sunset': tomorrowSunset},
    );
    final String iconAsset = WeatherUtils.getWeatherIconAsset(
      forecast.shortForecast,
      isNight: isNight,
    );

    return GestureDetector(
      onTap: () => showHourlyForecastDetailDialog(
        context: context,
        forecast: forecast,
        sunrise: sunrise,
        sunset: sunset,
        tomorrowSunrise: tomorrowSunrise,
        tomorrowSunset: tomorrowSunset,
      ),
      child: Container(
        color: Colors.transparent, // Explicit transparent background
        child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: UIConstants.spacingSmall, // Reduced from spacingStandard
          horizontal: UIConstants.spacingLarge, // Reduced from spacingXLarge
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              iconAsset,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: UIConstants.spacingLarge), // Reduced from spacingXLarge
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    flex: 0,
                    child: Text(
                      DateFormat('h a').format(forecast.time.toLocal()),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: UIConstants.spacingLarge), // Reduced from spacingXLarge
                  Expanded(
                    child: Text(
                      forecast.shortForecast,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: UIConstants.spacingLarge), // Reduced from spacingXLarge
            Text(
              '${forecast.temperature.round()}°F',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        ),
      ),
    );
  }
}


