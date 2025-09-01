import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_preferences_provider.dart';
// import '../theme/app_theme.dart';
import '../widgets/glass/glass_card.dart';
import 'notification_preferences_screen.dart';
import 'location_preferences_screen.dart';
// import '../providers/weather_provider.dart';
import '../screens/theme_settings_screen.dart';
import '../constants/ui_constants.dart';

enum SettingsPage { main, notifications, location, theme }

class SettingsScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  
  const SettingsScreen({super.key, this.onNavigate});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsPage _currentPage = SettingsPage.main;
  
  void _navigateToSubPage(SettingsPage page) {
    setState(() {
      _currentPage = page;
    });
  }
  
  void _navigateBack() {
    setState(() {
      _currentPage = SettingsPage.main;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
      child: _buildCurrentPage(),
    );
  }
  
  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case SettingsPage.main:
        return _buildMainSettingsPage();
      case SettingsPage.notifications:
        return _buildNotificationPage();
      case SettingsPage.location:
        return _buildLocationPage();
      case SettingsPage.theme:
        return _buildThemePage();
    }
  }
  
  Widget _buildMainSettingsPage() {
    return SafeArea(
      key: const ValueKey('main_settings'),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: UIConstants.spacingXLarge),
            GlassCard(
              priority: GlassCardPriority.prominent,
              contentPadding: const EdgeInsets.all(UIConstants.spacingXLarge),
              child: ListTile(
                leading: Icon(Icons.notifications, color: Theme.of(context).colorScheme.onSurface),
                title: Text('Notifications', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface),
                onTap: () => _navigateToSubPage(SettingsPage.notifications),
              ),
            ),
            const SizedBox(height: UIConstants.spacingXLarge),
            GlassCard(
              priority: GlassCardPriority.prominent,
              contentPadding: const EdgeInsets.all(UIConstants.spacingXLarge),
              child: ListTile(
                leading: Icon(Icons.location_on, color: Theme.of(context).colorScheme.onSurface),
                title: Text('Location', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface),
                onTap: () => _navigateToSubPage(SettingsPage.location),
              ),
            ),
            const SizedBox(height: UIConstants.spacingXLarge),
            GlassCard(
              priority: GlassCardPriority.prominent,
              contentPadding: const EdgeInsets.all(UIConstants.spacingXLarge),
              child: ListTile(
                leading: Icon(Icons.palette, color: Theme.of(context).colorScheme.onSurface),
                title: Text('Theme', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface),
                onTap: () => _navigateToSubPage(SettingsPage.theme),
              ),
            ),
            const SizedBox(height: UIConstants.spacingXLarge),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationPage() {
    return ChangeNotifierProvider(
      key: const ValueKey('notification_settings'),
      create: (_) => NotificationPreferencesProvider()..loadPreferences(),
      child: _SettingsPageWrapper(
        onBack: _navigateBack,
        child: const NotificationPreferencesScreen(),
      ),
    );
  }
  
  Widget _buildLocationPage() {
    return _SettingsPageWrapper(
      key: const ValueKey('location_settings'),
      onBack: _navigateBack,
      child: const LocationPreferencesScreen(),
    );
  }
  
  Widget _buildThemePage() {
    return _SettingsPageWrapper(
      key: const ValueKey('theme_settings'),
      onBack: _navigateBack,
      child: const ThemeSettingsScreen(),
    );
  }
}

class _SettingsPageWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onBack;
  
  const _SettingsPageWrapper({
    super.key,
    required this.child,
    required this.onBack,
  });
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onBack();
        return false;
      },
      child: child,
    );
  }
} 