import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/ui_constants.dart';
import '../models/weather_data.dart';
// import '../theme/app_theme.dart';
import '../utils/weather_utils.dart';
import 'dialogs/daily_forecast_detail_dialog.dart';


class DailyForecastListItem extends StatelessWidget {
  final DateTime date;
  final ForecastPeriod? dayPeriod;
  final ForecastPeriod? nightPeriod;

  const DailyForecastListItem({
    super.key,
    required this.date,
    required this.dayPeriod,
    required this.nightPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final ForecastPeriod? representative = dayPeriod ?? nightPeriod;
    final String iconAsset = WeatherUtils.getWeatherIconAsset(
      representative?.shortForecast,
      isNight: false,
    );

    final String dayLabel = DateFormat('EEE').format(date);
    final String shortForecast = representative?.shortForecast ?? '';
    final String trailingTemps = _formatHighLow(dayPeriod, nightPeriod);

    return GestureDetector(
      onTap: () => showDailyForecastDetailDialog(
        context: context,
        date: date,
        dayPeriod: dayPeriod,
        nightPeriod: nightPeriod,
        iconAsset: iconAsset,
      ),
      child: Container(
        color: Colors.transparent, // Explicit transparent background
        child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: UIConstants.spacingStandard, // Reduced from spacingLarge
          horizontal: UIConstants.spacingLarge, // Reduced from spacingXLarge
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              iconAsset,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: UIConstants.spacingLarge), // Reduced from spacingXLarge
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    flex: 0,
                    child: Text(
                      dayLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: UIConstants.spacingLarge), // Reduced from spacingXLarge
                  Expanded(
                    child: Text(
                      shortForecast,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: UIConstants.spacingLarge), // Reduced from spacingXLarge
            Text(
              trailingTemps,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _formatHighLow(ForecastPeriod? day, ForecastPeriod? night) {
    final String high = day != null ? '${day.temperature}°' : '--';
    final String low = night != null ? '${night.temperature}°' : '--';
    return '$high / $low';
  }
}


