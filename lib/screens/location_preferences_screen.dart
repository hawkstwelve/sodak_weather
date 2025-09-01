import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:provider/provider.dart';
// import '../providers/weather_provider.dart';
// import '../theme/app_theme.dart';
import '../widgets/glass/glass_card.dart';
import '../constants/ui_constants.dart';
import '../services/location_service.dart';

class LocationPreferencesScreen extends StatefulWidget {
  const LocationPreferencesScreen({super.key});

  @override
  State<LocationPreferencesScreen> createState() => _LocationPreferencesScreenState();
}

class _LocationPreferencesScreenState extends State<LocationPreferencesScreen> {
  LocationPermission? _permissionStatus;
  bool _isLocationServiceEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
  }

  Future<void> _loadPermissionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final permission = await LocationService.checkPermission();
      final isEnabled = await LocationService.isLocationServiceEnabled();
      
      // Check if widget is still mounted before calling setState
      if (!mounted) return;
      
      setState(() {
        _permissionStatus = permission;
        _isLocationServiceEnabled = isEnabled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getPermissionStatusText() {
    if (_permissionStatus == null) return 'Unknown';
    
    switch (_permissionStatus!) {
      case LocationPermission.denied:
        return 'Denied';
      case LocationPermission.deniedForever:
        return 'Permanently Denied';
      case LocationPermission.whileInUse:
        return 'While In Use';
      case LocationPermission.always:
        return 'Always';
      case LocationPermission.unableToDetermine:
        return 'Unable to Determine';
    }
  }

  Color _getPermissionStatusColor() {
    if (_permissionStatus == null) return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    
    switch (_permissionStatus!) {
      case LocationPermission.denied:
      case LocationPermission.deniedForever:
        return Colors.red;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return Colors.green;
      case LocationPermission.unableToDetermine:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    }
  }

  String _getPermissionDescription() {
    if (_permissionStatus == null) return 'Unable to determine permission status';
    
    switch (_permissionStatus!) {
      case LocationPermission.denied:
        return 'Location access is denied. You can request permission below.';
      case LocationPermission.deniedForever:
        return 'Location access is permanently denied. You\'ll need to enable it in your device settings.';
      case LocationPermission.whileInUse:
        return 'Location access is allowed while the app is in use.';
      case LocationPermission.always:
        return 'Location access is always allowed.';
      case LocationPermission.unableToDetermine:
        return 'Unable to determine location permission status.';
    }
  }

  Future<void> _requestPermission() async {
    try {
      final permission = await LocationService.requestPermission();
      setState(() {
        _permissionStatus = permission;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              permission == LocationPermission.denied || permission == LocationPermission.deniedForever
                  ? 'Location permission denied'
                  : 'Location permission granted',
            ),
            backgroundColor: permission == LocationPermission.denied || permission == LocationPermission.deniedForever
                ? Colors.red
                : Colors.green,
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
    await Geolocator.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.95,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: GlassCard(
              priority: GlassCardPriority.prominent,
              contentPadding: const EdgeInsets.all(UIConstants.spacingXXXLarge),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        _buildLocationServicesSection(),
                        const SizedBox(height: UIConstants.spacingXLarge),
                        _buildPermissionStatusSection(),
                        const SizedBox(height: UIConstants.spacingXLarge),
                        _buildPermissionActionsSection(),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location Services', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: UIConstants.spacingMedium),
        Row(
          children: [
            Icon(
              _isLocationServiceEnabled ? Icons.location_on : Icons.location_off,
              color: _isLocationServiceEnabled ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: UIConstants.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isLocationServiceEnabled ? 'Enabled' : 'Disabled', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _isLocationServiceEnabled ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  Text(_isLocationServiceEnabled ? 'Your device\'s location services are enabled' : 'Your device\'s location services are disabled. Please enable them in your device settings.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('App Permission Status', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: UIConstants.spacingMedium),
        Container(
          padding: const EdgeInsets.all(UIConstants.spacingLarge),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
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
                    _permissionStatus == LocationPermission.whileInUse || 
                    _permissionStatus == LocationPermission.always
                        ? Icons.check_circle
                        : Icons.error,
                    color: _getPermissionStatusColor(),
                  ),
                  const SizedBox(width: UIConstants.spacingMedium),
                  Expanded(
                    child: Text(_getPermissionStatusText(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _getPermissionStatusColor(), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.spacingMedium),
              Text(_getPermissionDescription(), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: UIConstants.spacingMedium),
        if (_permissionStatus == LocationPermission.denied) ...[
          ListTile(leading: Icon(Icons.location_on, color: Theme.of(context).colorScheme.onSurface), title: Text('Request Location Permission', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)), subtitle: Text('Ask for permission to access your location', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))), onTap: _requestPermission),
        ] else if (_permissionStatus == LocationPermission.deniedForever) ...[
          ListTile(leading: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface), title: Text('Open App Settings', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)), subtitle: Text('Enable location permission in device settings', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))), onTap: _openAppSettings),
        ] else ...[
          ListTile(leading: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface), title: Text('Refresh Permission Status', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)), subtitle: Text('Check current permission status', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))), onTap: _loadPermissionStatus),
        ],
        const SizedBox(height: UIConstants.spacingMedium),
        ListTile(leading: Icon(Icons.info, color: Theme.of(context).colorScheme.onSurface), title: Text('About Location Access', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)), subtitle: Text('Learn how location is used in this app', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: SingleChildScrollView(
                  child: GlassCard(
                    priority: GlassCardPriority.prominent,
                    child: Padding(
                      padding: const EdgeInsets.all(UIConstants.spacingXXXLarge),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Theme.of(context).colorScheme.onSurface, size: 28),
                              const SizedBox(width: UIConstants.spacingMedium),
                              Expanded(
                                child: Text('About Location Access', style: Theme.of(context).textTheme.headlineMedium),
                              ),
                            ],
                          ),
                          const SizedBox(height: UIConstants.spacingXLarge),
                          Text('This app uses your location to provide accurate weather information and alerts for your area. Location data is used to:', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: UIConstants.spacingMedium),
                          _buildBulletPoint('Get current weather conditions'),
                          _buildBulletPoint('Provide location-specific weather forecasts'),
                          _buildBulletPoint('Send weather alerts for your area'),
                          _buildBulletPoint('Show relevant radar data'),
                          const SizedBox(height: UIConstants.spacingMedium),
                          Text('Your location data is not shared with third parties and is only used for weather services.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontStyle: FontStyle.italic)),
                          const SizedBox(height: UIConstants.spacingXLarge),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Close', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(builder: (context) => Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(width: UIConstants.spacingMedium),
          Expanded(
            child: Builder(builder: (context) => Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ),
        ],
      ),
    );
  }
} 