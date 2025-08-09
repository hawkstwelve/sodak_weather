import 'package:flutter/material.dart';
import '../services/soil_moisture_service.dart';

/// Provider for managing soil moisture data and state
class SoilMoistureProvider with ChangeNotifier {
  final SoilMoistureService _service = SoilMoistureService();
  
  Map<String, String>? _soilMoistureUrls;
  bool _isLoading = false;
  String? _errorMessage;

  /// Current soil moisture URLs
  Map<String, String>? get soilMoistureUrls => _soilMoistureUrls;
  
  /// Whether data is currently being loaded
  bool get isLoading => _isLoading;
  
  /// Error message if data loading failed
  String? get errorMessage => _errorMessage;

  /// Fetch soil moisture data
  Future<void> fetchSoilMoistureData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final urls = await _service.getAllSoilMoistureUrls();
      _soilMoistureUrls = urls;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh soil moisture data
  Future<void> refreshData() async {
    await fetchSoilMoistureData();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get the NASA SPoRT website URL
  String getWebsiteUrl() {
    return _service.getWebsiteUrl();
  }

  /// Get URL for a specific depth
  String? getUrlForDepth(String depth) {
    return _soilMoistureUrls?[depth];
  }
} 