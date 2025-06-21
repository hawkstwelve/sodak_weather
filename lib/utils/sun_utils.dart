import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

/// Utility to extract sunrise/sunset for a given date from the raw forecastDays list.
Map<String, DateTime?> getSunriseSunsetForDate(List<dynamic> forecastDays, DateTime date, {String? timeZoneId}) {
  final dateStr = DateFormat('yyyy-MM-dd').format(date);
  for (final day in forecastDays) {
    if (day['displayDate'] != null) {
      final y = day['displayDate']['year'];
      final m = day['displayDate']['month'];
      final d = day['displayDate']['day'];
      final dayStr = DateFormat('yyyy-MM-dd').format(DateTime(y, m, d));
      if (dayStr == dateStr) {
        final sunEvents = day['sunEvents'];
        DateTime? sunriseUtc = sunEvents != null && sunEvents['sunriseTime'] != null ? DateTime.tryParse(sunEvents['sunriseTime']) : null;
        DateTime? sunsetUtc = sunEvents != null && sunEvents['sunsetTime'] != null ? DateTime.tryParse(sunEvents['sunsetTime']) : null;
        if (timeZoneId != null && sunriseUtc != null && sunsetUtc != null) {
          tzdata.initializeTimeZones();
          final location = tz.getLocation(timeZoneId);
          return {
            'sunrise': tz.TZDateTime.from(sunriseUtc, location),
            'sunset': tz.TZDateTime.from(sunsetUtc, location),
          };
        }
        return {
          'sunrise': sunriseUtc,
          'sunset': sunsetUtc,
        };
      }
    }
  }
  return {'sunrise': null, 'sunset': null};
}
