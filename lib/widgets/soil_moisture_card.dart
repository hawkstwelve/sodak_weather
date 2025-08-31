import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/soil_moisture_provider.dart';
import '../widgets/glass/glass_card.dart';
// import '../theme/app_theme.dart';
import '../constants/ui_constants.dart';

/// Widget for displaying soil moisture information in a glass card
class SoilMoistureCard extends StatelessWidget {
  final VoidCallback? onRefresh;

  const SoilMoistureCard({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SoilMoistureProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingCard();
        }

        if (provider.errorMessage != null) {
          return _buildErrorCard(context, provider);
        }

        if (provider.soilMoistureUrls == null) {
          return _buildEmptyCard(context, provider);
        }

        return _buildSoilMoistureCard(context, provider);
      },
    );
  }

  Widget _buildLoadingCard() {
    return GlassCard(
      priority: GlassCardPriority.standard,

      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Builder(builder: (context) => CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)))),
              const SizedBox(height: UIConstants.spacingLarge),
              Builder(builder: (context) => Text('Loading soil moisture data...', style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, SoilMoistureProvider provider) {
    return GlassCard(
      priority: GlassCardPriority.standard,

      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(builder: (context) => Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: UIConstants.iconSizeMedium)),
            const SizedBox(height: UIConstants.spacingLarge),
            Builder(builder: (context) => Text('Failed to load soil moisture data', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center)),
            const SizedBox(height: UIConstants.spacingMedium),
            Builder(builder: (context) => Text(provider.errorMessage ?? 'Unknown error', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center)),
            const SizedBox(height: UIConstants.spacingLarge),
            TextButton(
              onPressed: () {
                provider.clearError();
                provider.fetchSoilMoistureData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context, SoilMoistureProvider provider) {
    return GlassCard(
      priority: GlassCardPriority.standard,

      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(builder: (context) => Icon(Icons.water_drop_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: UIConstants.iconSizeMedium)),
            const SizedBox(height: UIConstants.spacingLarge),
            Text(
              'Soil Moisture',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingMedium),
            Text('NASA SPoRT soil moisture data for the Dakotas', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: UIConstants.spacingLarge),
            ElevatedButton(
              onPressed: () => provider.fetchSoilMoistureData(),
              child: const Text('Load Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilMoistureCard(BuildContext context, SoilMoistureProvider provider) {
    final urls = provider.soilMoistureUrls!;
    
    return GlassCard(
      priority: GlassCardPriority.standard,

      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soil Moisture',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: UIConstants.spacingLarge),
            
            // Soil moisture maps
            _buildSoilMoistureMaps(urls),
            
            const SizedBox(height: UIConstants.spacingLarge),
            
            // Data source info
            Text(
              'Updates every 24 hours',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            
            const SizedBox(height: UIConstants.spacingMedium),
            
            // Action button to view full data
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _launchUrl(provider.getWebsiteUrl()),
                icon: const Icon(Icons.open_in_new, size: UIConstants.iconSizeSmall),
                label: const Text('View Full Data'),
                style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface, side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilMoistureMaps(Map<String, String> urls) {
    final depths = [
      {'key': '0-10', 'label': '0-10cm (4")'},
      {'key': '0-40', 'label': '0-40cm (16")'},
      {'key': '0-100', 'label': '0-100cm (40")'},
    ];

    return Column(
      children: depths.map((depth) {
        final url = urls[depth['key']!];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(builder: (context) => Text('${depth['label']} Percentile', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.bold))),
            const SizedBox(height: UIConstants.spacingSmall),
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UIConstants.spacingLarge),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UIConstants.spacingLarge),
                child: url != null
                    ? Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.transparent,
                            child: Center(
                              child: Builder(builder: (context) => CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null)),
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
                                  Builder(builder: (context) => Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: UIConstants.iconSizeMedium)),
                                  const SizedBox(height: UIConstants.spacingMedium),
                                  Text(
                                    'Failed to load map',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.transparent,
                        child: Center(child: Builder(builder: (context) => CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))))),
                      ),
              ),
            ),
            if (depth['key'] != '0-100') const SizedBox(height: UIConstants.spacingLarge),
          ],
        );
      }).toList(),
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