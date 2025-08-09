import 'package:flutter/material.dart';
import '../models/drought_status.dart';
import '../services/drought_monitor_service.dart';

/// Provider for managing drought monitor data and state
class DroughtMonitorProvider with ChangeNotifier {
  final DroughtMonitorService _service = DroughtMonitorService();
  
  DroughtStatus? _droughtStatus;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentMapUrl;
  String? _currentDroughtMapUrl;
  String? _classChangeMapUrl;

  /// Current drought status data
  DroughtStatus? get droughtStatus => _droughtStatus;
  
  /// Whether data is currently being loaded
  bool get isLoading => _isLoading;
  
  /// Error message if data loading failed
  String? get errorMessage => _errorMessage;
  
  /// Current drought monitor map URL
  String? get currentMapUrl => _currentMapUrl;
  
  /// Current drought monitor image URL
  String? get currentDroughtMapUrl => _currentDroughtMapUrl;
  
  /// Class change map URL
  String? get classChangeMapUrl => _classChangeMapUrl;

  /// Fetch current drought monitor data
  Future<void> fetchDroughtData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final status = await _service.fetchDroughtStatus();
      final currentImageUrl = await _service.getCurrentDroughtMapUrl();
      final classChangeImageUrl = await _service.getClassChangeMapUrl();
      
      _droughtStatus = status;
      _currentMapUrl = currentImageUrl;
      _currentDroughtMapUrl = currentImageUrl;
      _classChangeMapUrl = classChangeImageUrl;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh drought data
  Future<void> refreshData() async {
    await fetchDroughtData();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get the full website URL for the drought monitor
  String getFullWebsiteUrl() {
    return _service.getFullWebsiteUrl();
  }

  /// Get the national map URL
  String getNationalMapUrl() {
    return _service.getNationalMapUrl();
  }

  /// Get the current drought map image URL
  String? getCurrentDroughtMapUrl() {
    return _currentDroughtMapUrl;
  }

  /// Get the class change map image URL
  String? getClassChangeMapUrl() {
    return _classChangeMapUrl;
  }
} 