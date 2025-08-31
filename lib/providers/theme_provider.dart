import 'package:flutter/material.dart';
import 'package:sodak_weather/models/theme_config.dart';
import 'package:sodak_weather/services/theme_persistence_service.dart';

/// Simplified provider that manages only theme color configuration
class ThemeProvider with ChangeNotifier {
  final ThemePersistenceService _persistenceService;
  ThemeConfig _config = ThemeConfig.defaults();

  ThemeProvider({ThemePersistenceService? persistenceService})
      : _persistenceService = persistenceService ?? const ThemePersistenceService();

  ThemeConfig get config => _config;

  Future<void> load() async {
    _config = await _persistenceService.loadThemeConfig();
    notifyListeners();
  }

  Future<void> setPrimary(Color color) async {
    _config = _config.copyWith(primary: color);
    await _persistenceService.saveThemeConfig(_config);
    notifyListeners();
  }

  Future<void> setAccent(Color color) async {
    _config = _config.copyWith(accent: color);
    await _persistenceService.saveThemeConfig(_config);
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _config = ThemeConfig.defaults();
    await _persistenceService.saveThemeConfig(_config);
    notifyListeners();
  }
}


