import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_preferences_provider.dart';
import '../providers/theme_provider.dart';
// import '../theme/app_theme.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/background/frosted_blob_background.dart';
import 'notification_preferences_screen.dart';
import 'location_preferences_screen.dart';
import 'notification_history_screen.dart';
// import '../providers/weather_provider.dart';
import '../screens/theme_settings_screen.dart';
import '../constants/ui_constants.dart';
import '../models/notification_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  
  const SettingsScreen({super.key, this.onNavigate});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingXLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: UIConstants.spacingXLarge),
              GlassCard(
                priority: GlassCardPriority.prominent,
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
                        return Center(child: Builder(builder: (context) => Text('Error: $error', style: Theme.of(context).textTheme.bodyLarge)));
                      }
                      
                      if (prefs == null) {
                        return const Center(child: Text('No preferences found.'));
                      }

                      return ListTile(
                        leading: Builder(builder: (context) => Icon(Icons.notifications, color: Theme.of(context).colorScheme.onSurface)),
                        title: Builder(builder: (context) => Text('Notifications', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface))),
                        trailing: Builder(builder: (context) => Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface)),
                        onTap: () {
                          if (!mounted) return;
                          final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FrostedBlobBackground(
                                themeConfig: themeProvider.config,
                                child: ChangeNotifierProvider.value(
                                  value: provider,
                                  child: const NotificationPreferencesScreen(),
                                ),
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
                priority: GlassCardPriority.prominent,
                contentPadding: const EdgeInsets.all(UIConstants.spacingXLarge),
                child: ListTile(
                  leading: Builder(builder: (context) => Icon(Icons.location_on, color: Theme.of(context).colorScheme.onSurface)),
                  title: Builder(builder: (context) => Text('Location', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface))),
                  trailing: Builder(builder: (context) => Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface)),
                  onTap: () {
                    if (!mounted) return;
                    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FrostedBlobBackground(
                          themeConfig: themeProvider.config,
                          child: const LocationPreferencesScreen(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: UIConstants.spacingXLarge),
              GlassCard(
                priority: GlassCardPriority.prominent,
                contentPadding: const EdgeInsets.all(UIConstants.spacingXLarge),
                child: ListTile(
                  leading: Builder(builder: (context) => Icon(Icons.palette, color: Theme.of(context).colorScheme.onSurface)),
                  title: Builder(builder: (context) => Text('Theme', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface))),
                  trailing: Builder(builder: (context) => Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface)),
                  onTap: () {
                    if (!mounted) return;
                    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FrostedBlobBackground(
                          themeConfig: themeProvider.config,
                          child: const ThemeSettingsScreen(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: UIConstants.spacingXLarge),
            ],
          ),
        ),
      );
  }
} 