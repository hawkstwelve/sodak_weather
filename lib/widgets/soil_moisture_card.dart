import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/soil_moisture_provider.dart';
import '../widgets/glass/glass_card.dart';
import '../theme/app_theme.dart';
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
      useBlur: false,
      opacity: UIConstants.opacityLow,
      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.loadingIndicatorColor),
              ),
              const SizedBox(height: UIConstants.spacingLarge),
              Text(
                'Loading soil moisture data...',
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, SoilMoistureProvider provider) {
    return GlassCard(
      useBlur: false,
      opacity: UIConstants.opacityLow,
      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.textMedium,
              size: UIConstants.iconSizeMedium,
            ),
            const SizedBox(height: UIConstants.spacingLarge),
            Text(
              'Failed to load soil moisture data',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingMedium),
            Text(
              provider.errorMessage ?? 'Unknown error',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
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
      useBlur: false,
      opacity: UIConstants.opacityLow,
      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.water_drop_outlined,
              color: AppTheme.textMedium,
              size: UIConstants.iconSizeMedium,
            ),
            const SizedBox(height: UIConstants.spacingLarge),
            Text(
              'Soil Moisture',
              style: AppTheme.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingMedium),
            Text(
              'NASA SPoRT soil moisture data for the Dakotas',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
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
      useBlur: false,
      opacity: UIConstants.opacityLow,
      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soil Moisture',
              style: AppTheme.headingSmall,
            ),
            const SizedBox(height: UIConstants.spacingLarge),
            
            // Soil moisture maps
            _buildSoilMoistureMaps(urls),
            
            const SizedBox(height: UIConstants.spacingLarge),
            
            // Data source info
            Text(
              'Updates every 24 hours',
              style: AppTheme.bodySmall,
            ),
            
            const SizedBox(height: UIConstants.spacingMedium),
            
            // Action button to view full data
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _launchUrl(provider.getWebsiteUrl()),
                icon: const Icon(Icons.open_in_new, size: UIConstants.iconSizeSmall),
                label: const Text('View Full Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textLight,
                  side: const BorderSide(color: AppTheme.textMedium),
                ),
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
            Text(
              '${depth['label']} Percentile',
              style: AppTheme.bodyBold.copyWith(
                color: AppTheme.textMedium,
                fontSize: 14,
              ),
            ),
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
                              child: CircularProgressIndicator(
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.loadingIndicatorColor),
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
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppTheme.textMedium,
                                    size: UIConstants.iconSizeMedium,
                                  ),
                                  const SizedBox(height: UIConstants.spacingMedium),
                                  Text(
                                    'Failed to load map',
                                    style: AppTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.transparent,
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.loadingIndicatorColor),
                          ),
                        ),
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