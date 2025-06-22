// Almanac data model for historical weather information
class AlmanacData {
  final double recordHighTemp;
  final int recordHighYear;
  final double recordLowTemp;
  final int recordLowYear;
  final double recordPrecip;
  final int recordPrecipYear;
  final double averageHigh;
  final double averageLow;
  final double averagePrecipitation;
  final List<YearlyData> recentYears;

  AlmanacData({
    required this.recordHighTemp,
    required this.recordHighYear,
    required this.recordLowTemp,
    required this.recordLowYear,
    required this.recordPrecip,
    required this.recordPrecipYear,
    required this.averageHigh,
    required this.averageLow,
    required this.averagePrecipitation,
    required this.recentYears,
  });
}

class YearlyData {
  final int year;
  final double highTemp;
  final double lowTemp;
  final double precip;

  YearlyData({
    required this.year,
    required this.highTemp,
    required this.lowTemp,
    required this.precip,
  });
} 