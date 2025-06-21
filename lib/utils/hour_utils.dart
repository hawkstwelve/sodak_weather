import 'package:intl/intl.dart';

/// Returns true if the given [hour] is considered night, based on sunrise/sunset times.
bool isNightHour(DateTime hour, DateTime? sunrise, DateTime? sunset) {
  if (sunrise == null || sunset == null) return hour.hour < 6 || hour.hour > 18;
  // If hour is before sunrise or after sunset, it's night
  return hour.isBefore(sunrise) || hour.isAfter(sunset);
}

/// Returns true if the given [hour] is considered night, based on sunrise/sunset times for multiple days.
/// This function handles hourly forecasts that span multiple days.
bool isNightHourMultiDay(DateTime hour, Map<String, DateTime?> todaySunEvents, Map<String, DateTime?> tomorrowSunEvents) {
  final hourDate = DateFormat('yyyy-MM-dd').format(hour);
  final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final tomorrowDate = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));
  
  DateTime? sunrise;
  DateTime? sunset;
  
  if (hourDate == todayDate) {
    sunrise = todaySunEvents['sunrise'];
    sunset = todaySunEvents['sunset'];
  } else if (hourDate == tomorrowDate) {
    sunrise = tomorrowSunEvents['sunrise'];
    sunset = tomorrowSunEvents['sunset'];
  }
  
  if (sunrise == null || sunset == null) {
    return hour.hour < 6 || hour.hour > 18;
  }
  
  return hour.isBefore(sunrise) || hour.isAfter(sunset);
}
