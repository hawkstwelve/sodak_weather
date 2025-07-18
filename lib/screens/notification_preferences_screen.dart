import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../providers/notification_preferences_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass/glass_card.dart';
import '../providers/weather_provider.dart';
import '../models/notification_preferences.dart';
import 'notification_history_screen.dart';
import '../constants/ui_constants.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _alertTypesExpanded = false;
  bool _doNotDisturbExpanded = false;
  NotificationSettings? _notificationSettings;
  bool _isLoadingPermissions = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPermissions();
  }

  Future<void> _loadNotificationPermissions() async {
    setState(() {
      _isLoadingPermissions = true;
    });

    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      setState(() {
        _notificationSettings = settings;
        _isLoadingPermissions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPermissions = false;
      });
    }
  }

  String _getPermissionStatusText() {
    if (_notificationSettings == null) return 'Unknown';
    
    switch (_notificationSettings!.authorizationStatus) {
      case AuthorizationStatus.authorized:
        return 'Allowed';
      case AuthorizationStatus.denied:
        return 'Denied';
      case AuthorizationStatus.notDetermined:
        return 'Not Determined';
      case AuthorizationStatus.provisional:
        return 'Provisional';
    }
  }

  Color _getPermissionStatusColor() {
    if (_notificationSettings == null) return AppTheme.textMedium;
    
    switch (_notificationSettings!.authorizationStatus) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return Colors.green;
      case AuthorizationStatus.denied:
        return Colors.red;
      case AuthorizationStatus.notDetermined:
        return AppTheme.textMedium;
    }
  }

  String _getPermissionDescription() {
    if (_notificationSettings == null) return 'Unable to determine notification permission status';
    
    switch (_notificationSettings!.authorizationStatus) {
      case AuthorizationStatus.authorized:
        return 'Notifications are allowed. You will receive weather alerts and updates.';
      case AuthorizationStatus.denied:
        return 'Notifications are denied. You can request permission below to receive weather alerts.';
      case AuthorizationStatus.notDetermined:
        return 'Notification permission has not been determined. You can request permission below.';
      case AuthorizationStatus.provisional:
        return 'Notifications are provisionally allowed. You will receive weather alerts.';
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      setState(() {
        _notificationSettings = settings;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settings.authorizationStatus == AuthorizationStatus.authorized || 
              settings.authorizationStatus == AuthorizationStatus.provisional
                  ? 'Notification permission granted'
                  : 'Notification permission denied',
            ),
            backgroundColor: settings.authorizationStatus == AuthorizationStatus.authorized || 
                settings.authorizationStatus == AuthorizationStatus.provisional
                ? Colors.green
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAppSettings() async {
    // For notification permissions, we'll show a dialog directing users to settings
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SingleChildScrollView(
            child: GlassCard(
              useBlur: true,
              child: Padding(
                padding: const EdgeInsets.all(UIConstants.spacingXXXLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings, color: AppTheme.textLight, size: 28),
                        const SizedBox(width: UIConstants.spacingMedium),
                        Expanded(
                          child: Text(
                            'Notification Settings',
                            style: AppTheme.headingMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: UIConstants.spacingXLarge),
                    Text(
                      'To manage notification permissions, please go to your device settings:',
                      style: AppTheme.bodyMedium,
                    ),
                    const SizedBox(height: UIConstants.spacingMedium),
                    _buildBulletPoint('iOS: Settings > Notifications > Sodak Weather'),
                    _buildBulletPoint('Android: Settings > Apps > Sodak Weather > Notifications'),
                    const SizedBox(height: UIConstants.spacingXLarge),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: AppTheme.textBlue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: AppTheme.textLight),
          const SizedBox(width: UIConstants.spacingMedium),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationPreferencesProvider>(context);
    final prefs = provider.preferences;
    final loading = provider.loading;
    final error = provider.error;
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final condition = weatherProvider.weatherData?.currentConditions?.textDescription;
    final gradient = AppTheme.getGradientForCondition(condition);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textLight,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.95,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: GlassCard(
                  useBlur: true,
                  contentPadding: const EdgeInsets.all(UIConstants.spacingXXXLarge),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : error != null
                          ? Center(child: Text('Error: $error', style: AppTheme.bodyLarge))
                          : prefs == null
                              ? const Center(child: Text('No preferences found.'))
                              : ListView(
                                  shrinkWrap: true,
                                  children: [
                                    _buildNotificationPermissionSection(),
                                    _buildAlertTypesSection(prefs, provider),
                                    _buildDoNotDisturbSection(prefs, provider),
                                    _buildNotificationHistorySection(),
                                  ],
                                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationPermissionSection() {
    return Column(
      children: [
        Text(
          'Notification Permissions',
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: UIConstants.spacingMedium),
        if (_isLoadingPermissions) ...[
          const Center(child: CircularProgressIndicator()),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(UIConstants.spacingLarge),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: _getPermissionStatusColor().withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _notificationSettings?.authorizationStatus == AuthorizationStatus.authorized || 
                      _notificationSettings?.authorizationStatus == AuthorizationStatus.provisional
                          ? Icons.check_circle
                          : Icons.error,
                      color: _getPermissionStatusColor(),
                    ),
                    const SizedBox(width: UIConstants.spacingMedium),
                    Text(
                      _getPermissionStatusText(),
                      style: AppTheme.bodyMedium.copyWith(
                        color: _getPermissionStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UIConstants.spacingMedium),
                Text(
                  _getPermissionDescription(),
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: UIConstants.spacingMedium),
          if (_notificationSettings?.authorizationStatus == AuthorizationStatus.denied) ...[
            ListTile(
              leading: const Icon(Icons.notifications, color: AppTheme.textLight),
              title: const Text('Request Notification Permission', style: TextStyle(color: AppTheme.textLight)),
              subtitle: const Text('Ask for permission to send notifications', style: TextStyle(color: AppTheme.textMedium)),
              onTap: _requestNotificationPermission,
            ),
          ] else if (_notificationSettings?.authorizationStatus == AuthorizationStatus.authorized || 
                     _notificationSettings?.authorizationStatus == AuthorizationStatus.provisional) ...[
            ListTile(
              leading: const Icon(Icons.refresh, color: AppTheme.textLight),
              title: const Text('Refresh Permission Status', style: TextStyle(color: AppTheme.textLight)),
              subtitle: const Text('Check current permission status', style: TextStyle(color: AppTheme.textMedium)),
              onTap: _loadNotificationPermissions,
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.settings, color: AppTheme.textLight),
              title: const Text('Open App Settings', style: TextStyle(color: AppTheme.textLight)),
              subtitle: const Text('Manage notification permissions in device settings', style: TextStyle(color: AppTheme.textMedium)),
              onTap: _openAppSettings,
            ),
          ],
        ],
        Divider(height: UIConstants.spacingHuge, color: AppTheme.textLight.withValues(alpha: UIConstants.opacityLow)),
      ],
    );
  }

  Widget _buildAlertTypesSection(NotificationPreferences prefs, NotificationPreferencesProvider provider) {
    return Column(
      children: [
        ExpansionTile(
          title: Text('Alert Types', style: AppTheme.bodyLarge),
          subtitle: Text(
            'All weather alerts enabled',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textMedium),
          ),
          initiallyExpanded: _alertTypesExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _alertTypesExpanded = expanded;
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.all(UIConstants.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comprehensive Weather Alerts',
                    style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: UIConstants.spacingMedium),
                  Text(
                    'All weather alert types are enabled by default to ensure you receive important weather information for your area. This includes:',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textMedium),
                  ),
                  const SizedBox(height: UIConstants.spacingMedium),
                  Text(
                    '• Severe weather warnings and watches\n'
                    '• Flood and flash flood alerts\n'
                    '• Winter weather conditions\n'
                    '• Extreme heat and cold warnings\n'
                    '• Fire weather alerts\n'
                    '• Air quality and smoke advisories\n'
                    '• Wind and fog conditions\n'
                    '• Emergency notifications',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textMedium),
                  ),
                  const SizedBox(height: UIConstants.spacingMedium),
                  Text(
                    'You can still control when you receive notifications using the Do Not Disturb settings below.',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textMedium,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Divider(height: UIConstants.spacingHuge, color: AppTheme.textLight.withValues(alpha: UIConstants.opacityLow)),
      ],
    );
  }

  Widget _buildDoNotDisturbSection(NotificationPreferences prefs, NotificationPreferencesProvider provider) {
    return Column(
      children: [
        ExpansionTile(
          title: Text('Do Not Disturb', style: AppTheme.bodyLarge),
          subtitle: Text(
            prefs.doNotDisturb?.enabled ?? false 
                ? 'Enabled (${prefs.doNotDisturb?.startHour.toString().padLeft(2, '0')}:00 - ${prefs.doNotDisturb?.endHour.toString().padLeft(2, '0')}:00)'
                : 'Disabled',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textMedium),
          ),
          initiallyExpanded: _doNotDisturbExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _doNotDisturbExpanded = expanded;
            });
          },
          children: [
            SwitchListTile(
              title: const Text('Enable Do Not Disturb'),
              value: prefs.doNotDisturb?.enabled ?? false,
              onChanged: (val) async {
                final updated = NotificationPreferences(
                  enabledAlertTypes: prefs.enabledAlertTypes,
                  doNotDisturb: DoNotDisturb(
                    enabled: val,
                    startHour: prefs.doNotDisturb?.startHour ?? 22,
                    endHour: prefs.doNotDisturb?.endHour ?? 7,
                  ),
                  lastUpdated: DateTime.now(),
                );
                await provider.savePreferences(updated);
                if (!mounted) return;
                showGlassCardSnackbar(context, 'Preferences saved');
              },
            ),
            if (prefs.doNotDisturb?.enabled ?? false) ...[
              Row(
                children: [
                  const Text('Start:'),
                  const SizedBox(width: UIConstants.spacingStandard),
                  DropdownButton<int>(
                    value: prefs.doNotDisturb?.startHour ?? 22,
                    items: List.generate(24, (i) => DropdownMenuItem(
                      value: i,
                      child: Text('${i.toString().padLeft(2, '0')}:00'),
                    )),
                    onChanged: (val) async {
                      if (val == null) return;
                      final updated = NotificationPreferences(
                        enabledAlertTypes: prefs.enabledAlertTypes,
                        doNotDisturb: DoNotDisturb(
                          enabled: true,
                          startHour: val,
                          endHour: prefs.doNotDisturb?.endHour ?? 7,
                        ),
                        lastUpdated: DateTime.now(),
                      );
                      await provider.savePreferences(updated);
                      if (!mounted) return;
                      showGlassCardSnackbar(context, 'Preferences saved');
                    },
                  ),
                  const SizedBox(width: UIConstants.spacingXLarge),
                  const Text('End:'),
                  const SizedBox(width: UIConstants.spacingStandard),
                  DropdownButton<int>(
                    value: prefs.doNotDisturb?.endHour ?? 7,
                    items: List.generate(24, (i) => DropdownMenuItem(
                      value: i,
                      child: Text('${i.toString().padLeft(2, '0')}:00'),
                    )),
                    onChanged: (val) async {
                      if (val == null) return;
                      final updated = NotificationPreferences(
                        enabledAlertTypes: prefs.enabledAlertTypes,
                        doNotDisturb: DoNotDisturb(
                          enabled: true,
                          startHour: prefs.doNotDisturb?.startHour ?? 22,
                          endHour: val,
                        ),
                        lastUpdated: DateTime.now(),
                      );
                      await provider.savePreferences(updated);
                      if (!mounted) return;
                      showGlassCardSnackbar(context, 'Preferences saved');
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
        Divider(height: UIConstants.spacingHuge, color: AppTheme.textLight.withValues(alpha: UIConstants.opacityLow)),
      ],
    );
  }

  Widget _buildNotificationHistorySection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.history, color: AppTheme.textLight),
          title: const Text('Notification History', style: TextStyle(color: AppTheme.textLight)),
          subtitle: const Text('View past weather alerts', style: TextStyle(color: AppTheme.textMedium)),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationHistoryScreen(),
              ),
            );
          },
        ),
        Divider(height: UIConstants.spacingHuge, color: AppTheme.textLight.withValues(alpha: UIConstants.opacityLow)),
      ],
    );
  }
}

void showGlassCardSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
} 