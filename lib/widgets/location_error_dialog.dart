import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import '../providers/location_provider.dart';
// import '../theme/app_theme.dart';
import 'glass/glass_card.dart';
import '../constants/ui_constants.dart';

/// Dialog for displaying location-related errors with appropriate actions
class LocationErrorDialog extends StatelessWidget {
  final LocationErrorType errorType;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const LocationErrorDialog({
    super.key,
    required this.errorType,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        priority: GlassCardPriority.prominent,
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingXXXLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Icon
              Container(
                padding: const EdgeInsets.all(UIConstants.spacingXLarge),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: UIConstants.opacityVeryLow),
                  borderRadius: BorderRadius.circular(UIConstants.iconSizeLarge),
                ),
                child: Icon(
                  _getErrorIcon(),
                  color: Theme.of(context).colorScheme.error,
                  size: UIConstants.iconSizeLarge,
                ),
              ),
              const SizedBox(height: UIConstants.spacingXLarge),

              // Error Title
              Builder(builder: (context) => Text(_getErrorTitle(), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              const SizedBox(height: UIConstants.spacingLarge),

              // Error Message
              Builder(builder: (context) => Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)), textAlign: TextAlign.center)),
              const SizedBox(height: UIConstants.spacingXXXLarge),

              // Action Buttons
              Row(
                children: [
                  // Dismiss Button
                  Expanded(
                    child: TextButton(
                      onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: UIConstants.spacingLarge),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UIConstants.spacingLarge),
                        ),
                      ),
                      child: Builder(builder: (context) => Text('Cancel', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))))
                    ),
                  ),
                  const SizedBox(width: UIConstants.spacingLarge),

                  // Action Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleAction(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: UIConstants.spacingLarge),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UIConstants.spacingLarge),
                        ),
                      ),
                      child: Builder(builder: (context) => Text(_getActionButtonText(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.w600))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (errorType) {
      case LocationErrorType.permissionDenied:
      case LocationErrorType.permissionDeniedForever:
        return Icons.location_off;
      case LocationErrorType.locationServicesDisabled:
        return Icons.gps_off;
      case LocationErrorType.locationTimeout:
        return Icons.timer_off;
      case LocationErrorType.networkError:
        return Icons.wifi_off;
      case LocationErrorType.unknown:
        return Icons.error_outline;
    }
  }

  String _getErrorTitle() {
    switch (errorType) {
      case LocationErrorType.permissionDenied:
        return 'Location Permission Required';
      case LocationErrorType.permissionDeniedForever:
        return 'Location Access Blocked';
      case LocationErrorType.locationServicesDisabled:
        return 'Location Services Disabled';
      case LocationErrorType.locationTimeout:
        return 'Location Request Timeout';
      case LocationErrorType.networkError:
        return 'Network Error';
      case LocationErrorType.unknown:
        return 'Location Error';
    }
  }

  String _getActionButtonText() {
    switch (errorType) {
      case LocationErrorType.permissionDenied:
      case LocationErrorType.permissionDeniedForever:
        return 'Open Settings';
      case LocationErrorType.locationServicesDisabled:
        return 'Enable GPS';
      case LocationErrorType.locationTimeout:
      case LocationErrorType.networkError:
      case LocationErrorType.unknown:
        return 'Try Again';
    }
  }

  void _handleAction(BuildContext context) {
    switch (errorType) {
      case LocationErrorType.permissionDenied:
      case LocationErrorType.permissionDeniedForever:
        _openLocationSettings();
        Navigator.of(context).pop();
        break;
      case LocationErrorType.locationServicesDisabled:
        _openLocationSettings();
        Navigator.of(context).pop();
        break;
      case LocationErrorType.locationTimeout:
      case LocationErrorType.networkError:
      case LocationErrorType.unknown:
        Navigator.of(context).pop();
        onRetry?.call();
        break;
    }
  }

  void _openLocationSettings() {
    AppSettings.openAppSettings(type: AppSettingsType.location);
  }
}

/// Show location error dialog
Future<void> showLocationErrorDialog({
  required BuildContext context,
  required LocationErrorType errorType,
  required String message,
  VoidCallback? onRetry,
  VoidCallback? onDismiss,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => LocationErrorDialog(
      errorType: errorType,
      message: message,
      onRetry: onRetry,
      onDismiss: onDismiss,
    ),
  );
} 