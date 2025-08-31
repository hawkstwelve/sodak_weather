import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/drought_monitor_provider.dart';
import '../widgets/glass/glass_card.dart';
// import '../theme/app_theme.dart';
import '../constants/ui_constants.dart';

/// Widget for displaying drought monitor information in a glass card
class DroughtMonitorCard extends StatelessWidget {
  final VoidCallback? onRefresh;

  const DroughtMonitorCard({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DroughtMonitorProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingCard(context);
        }

        if (provider.errorMessage != null) {
          return _buildErrorCard(context, provider);
        }

        if (provider.droughtStatus == null) {
          return _buildEmptyCard(context, provider);
        }

        return _buildDroughtCard(context, provider);
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return GlassCard(
      priority: GlassCardPriority.standard,

      child: Container(
        height: UIConstants.cardHeightLarge,
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: UIConstants.spacingLarge),
              Text('Loading drought data...', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, DroughtMonitorProvider provider) {
    return GlassCard(
      priority: GlassCardPriority.standard,

      child: Container(
        height: UIConstants.cardHeightLarge,
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: UIConstants.iconSizeMedium),
            const SizedBox(height: UIConstants.spacingLarge),
            Text('Failed to load drought data', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: UIConstants.spacingMedium),
            Text(provider.errorMessage ?? 'Unknown error', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: UIConstants.spacingLarge),
            TextButton(
              onPressed: () {
                provider.clearError();
                provider.fetchDroughtData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context, DroughtMonitorProvider provider) {
    return GlassCard(
      priority: GlassCardPriority.standard,

      child: Container(
        height: UIConstants.cardHeightLarge,
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: UIConstants.iconSizeMedium),
            const SizedBox(height: UIConstants.spacingLarge),
            Text('Drought Monitor', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: UIConstants.spacingMedium),
            Text('Current drought conditions in South Dakota', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: UIConstants.spacingLarge),
            ElevatedButton(
              onPressed: () => provider.fetchDroughtData(),
              child: const Text('Load Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDroughtCard(BuildContext context, DroughtMonitorProvider provider) {
    
    return GlassCard(
      priority: GlassCardPriority.standard,

      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Drought Monitor', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: UIConstants.spacingLarge),
            
            // Current drought monitor map image
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: UIConstants.spacingSmall),
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(UIConstants.spacingLarge),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(UIConstants.spacingLarge),
                    child: provider.currentDroughtMapUrl != null
                        ? Image.network(
                            provider.currentDroughtMapUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.transparent,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.transparent,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: UIConstants.iconSizeMedium),
                                      const SizedBox(height: UIConstants.spacingMedium),
                                      Text('Failed to load map', style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.transparent,
                            child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary))),
                          ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: UIConstants.spacingLarge),
            
            // Class change map image
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Class Change (1 Month)', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: UIConstants.spacingSmall),
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(UIConstants.spacingLarge),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(UIConstants.spacingLarge),
                    child: provider.classChangeMapUrl != null
                        ? Image.network(
                            provider.classChangeMapUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.transparent,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.transparent,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: UIConstants.iconSizeMedium),
                                      const SizedBox(height: UIConstants.spacingMedium),
                                      Text('Failed to load map', style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.transparent,
                            child: Center(
                              child: Builder(
                                builder: (context) => CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: UIConstants.spacingLarge),
            
            // Last updated info
            Text('Updates every Thursday', style: Theme.of(context).textTheme.bodySmall),
            
            const SizedBox(height: UIConstants.spacingLarge),
            
            // Action button to view full data
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _launchUrl('https://droughtmonitor.unl.edu/CurrentMap/StateDroughtMonitor.aspx?SD'),
                icon: const Icon(Icons.open_in_new, size: UIConstants.iconSizeSmall),
                label: const Text('View Full Data'),
                style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface, side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback: try to launch in browser
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      // If all else fails, try to launch with inAppWebView mode
      try {
        final uri = Uri.parse(url);
        await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );
      } catch (e2) {
        // Log the error but don't crash the app
        debugPrint('Failed to launch URL: $url, Error: $e2');
      }
    }
  }
} 