import 'package:shared_preferences/shared_preferences.dart';
import 'package:sodak_weather/models/theme_config.dart';

/// Simplified service for persisting theme colors only
class ThemePersistenceService {
  static const String _keyPrimary = 'theme.primary';
  static const String _keyAccent = 'theme.accent';

  const ThemePersistenceService();

  Future<ThemeConfig> loadThemeConfig() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? primary = prefs.getInt(_keyPrimary);
    final int? accent = prefs.getInt(_keyAccent);
    final Map<String, Object?> map = {
      'primary': primary,
      'accent': accent,
    };
    return ThemeConfig.fromMap(map);
  }

  Future<void> saveThemeConfig(ThemeConfig config) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPrimary, config.primary.toARGB32());
    await prefs.setInt(_keyAccent, config.accent.toARGB32());
  }
}


