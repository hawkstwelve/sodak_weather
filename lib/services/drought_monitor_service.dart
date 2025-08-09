import '../models/drought_status.dart';

/// Service for fetching drought monitor data from UNL
class DroughtMonitorService {
  static const String _baseUrl = 'https://droughtmonitor.unl.edu';
  static const String _stateCode = 'SD'; // South Dakota
  static const String _currentImageUrl = 'https://droughtmonitor.unl.edu/data/png/current/current_sd_trd.png';
  static const String _classChangeImageUrl = 'https://droughtmonitor.unl.edu/data/chng/png/current/current_SD_chng_4W.png';
  
  /// Get the current drought monitor map URL
  Future<String> getCurrentDroughtMapUrl() async {
    return _currentImageUrl;
  }

  /// Get the 4-week class change map URL
  Future<String> getClassChangeMapUrl() async {
    return _classChangeImageUrl;
  }

  /// Fetch drought status information for South Dakota
  Future<DroughtStatus> fetchDroughtStatus() async {
    try {
      return DroughtStatus(
        category: 'Current', // Will be updated when we implement actual data parsing
        description: 'Current drought conditions in South Dakota',
        lastUpdated: DateTime.now(),
        mapUrl: _currentImageUrl,
        stateSpecificUrl: '$_baseUrl/CurrentMap/StateDroughtMonitor.aspx?$_stateCode',
      );
    } catch (e) {
      throw Exception('Error fetching drought status: $e');
    }
  }

  /// Get the URL for the full drought monitor website
  String getFullWebsiteUrl() {
    return '$_baseUrl/CurrentMap/StateDroughtMonitor.aspx?$_stateCode';
  }

  /// Get the URL for the national drought monitor
  String getNationalMapUrl() {
    return '$_baseUrl/CurrentMap/StateDroughtMonitor.aspx?High_Plains';
  }
} 