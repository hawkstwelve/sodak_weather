import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/ui_constants.dart';
import '../models/hourly_forecast.dart';
import '../theme/app_theme.dart';
import '../utils/hour_utils.dart';
import '../utils/weather_utils.dart';
import 'dialogs/hourly_forecast_detail_dialog.dart';
import 'glass/glass_card.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacingXLarge),
      child: GestureDetector(
        onTap: () => showHourlyForecastDetailDialog(
          context: context,
          forecast: forecast,
          sunrise: sunrise,
          sunset: sunset,
          tomorrowSunrise: tomorrowSunrise,
          tomorrowSunset: tomorrowSunset,
        ),
        child: GlassCard(
          useBlur: false,
          opacity: UIConstants.opacityVeryLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: UIConstants.spacingStandard,
              horizontal: UIConstants.spacingXLarge,
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
                const SizedBox(width: UIConstants.spacingXLarge),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        flex: 0,
                        child: Text(
                          DateFormat('h a').format(forecast.time.toLocal()),
                          style: AppTheme.bodyBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: UIConstants.spacingLarge),
                      Expanded(
                        child: Text(
                          forecast.shortForecast,
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.textMedium),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: UIConstants.spacingXLarge),
                Text(
                  '${forecast.temperature.round()}°F',
                  style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


