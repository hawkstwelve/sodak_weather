import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_preferences_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass/glass_card.dart';
import 'notification_preferences_screen.dart';
import 'location_preferences_screen.dart';
import '../providers/weather_provider.dart';
import '../constants/ui_constants.dart';

class SettingsScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  
  const SettingsScreen({super.key, this.onNavigate});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final condition = weatherProvider.weatherData?.currentConditions?.textDescription;
    final gradient = AppTheme.getGradientForCondition(condition);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingXLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: UIConstants.spacingXLarge),
              GlassCard(
                useBlur: true,
                contentPadding: const EdgeInsets.all(UIConstants.spacingXLarge),
                child: ChangeNotifierProvider(
                  create: (_) => NotificationPreferencesProvider()..loadPreferences(),
                  child: Consumer<NotificationPreferencesProvider>(
                    builder: (context, provider, _) {
                      final prefs = provider.preferences;
                      final loading = provider.loading;
                      final error = provider.error;

                      if (loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (error != null) {
                        return Center(child: Text('Error: $error', style: AppTheme.bodyLarge));
                      }
                      
                      if (prefs == null) {
                        return const Center(child: Text('No preferences found.'));
                      }

                      return ListTile(
                        leading: const Icon(Icons.notifications, color: AppTheme.textLight),
                        title: const Text('Notifications', style: TextStyle(color: AppTheme.textLight)),
                        trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                        onTap: () {
                          if (!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: provider,
                                child: const NotificationPreferencesScreen(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: UIConstants.spacingXLarge),
              GlassCard(
                useBlur: true,
                contentPadding: const EdgeInsets.all(UIConstants.spacingXLarge),
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: AppTheme.textLight),
                  title: const Text('Location', style: TextStyle(color: AppTheme.textLight)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                  onTap: () {
                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LocationPreferencesScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: UIConstants.spacingXLarge),
            ],
          ),
        ),
      ),
    );
  }
} 