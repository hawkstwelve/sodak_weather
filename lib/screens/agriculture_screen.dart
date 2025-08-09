import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/drought_monitor_provider.dart';
import '../providers/soil_moisture_provider.dart';
import '../widgets/drought_monitor_card.dart';
import '../widgets/soil_moisture_card.dart';
import '../widgets/glass/glass_card.dart';
import '../theme/app_theme.dart';
import '../constants/ui_constants.dart';

/// Agriculture screen displaying agricultural weather information
class AgricultureScreen extends StatefulWidget {
  final Widget? citySelector;
  final Function(int)? onNavigate;
  final String? currentScreenId;

  const AgricultureScreen({
    super.key,
    this.citySelector,
    this.onNavigate,
    this.currentScreenId,
  });

  @override
  State<AgricultureScreen> createState() => _AgricultureScreenState();
}

class _AgricultureScreenState extends State<AgricultureScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final droughtProvider = Provider.of<DroughtMonitorProvider>(context, listen: false);
      final soilMoistureProvider = Provider.of<SoilMoistureProvider>(context, listen: false);
      droughtProvider.fetchDroughtData();
      soilMoistureProvider.fetchSoilMoistureData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryMedium,
              AppTheme.primaryLight,
            ],
          ),
        ),
        child: SafeArea(
                  child: RefreshIndicator(
          onRefresh: () async {
            final droughtProvider = Provider.of<DroughtMonitorProvider>(context, listen: false);
            final soilMoistureProvider = Provider.of<SoilMoistureProvider>(context, listen: false);
            await Future.wait([
              droughtProvider.refreshData(),
              soilMoistureProvider.refreshData(),
            ]);
          },
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacingXLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: UIConstants.spacingXLarge),
          
          // Drought Monitor Section
          const DroughtMonitorCard(),
          
          const SizedBox(height: UIConstants.spacingXXXLarge),
          
          // Soil Moisture Section
          const SoilMoistureCard(),
          
          const SizedBox(height: UIConstants.spacingXXXLarge),
          
          // Coming Soon Section
          _buildComingSoonSection(),
          
          const SizedBox(height: UIConstants.spacingXXXLarge),
          // Add extra padding at bottom to prevent black bar
          const SizedBox(height: UIConstants.spacingXXXLarge),
        ],
      ),
    );
  }

  Widget _buildComingSoonSection() {
    return GlassCard(
      useBlur: false,
      opacity: UIConstants.opacityLow,
      child: Container(
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.agriculture,
                  color: AppTheme.textMedium,
                  size: UIConstants.iconSizeMedium,
                ),
                const SizedBox(width: UIConstants.spacingMedium),
                Text(
                  'Coming Soon',
                  style: AppTheme.headingSmall,
                ),
              ],
            ),
            const SizedBox(height: UIConstants.spacingLarge),
            Text(
              'Additional agricultural features will be available soon:',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: UIConstants.spacingLarge),
            _buildFeatureItem('Growing Degree Days', 'Crop development tracking'),
            _buildFeatureItem('Frost Alerts', 'Early and late frost warnings'),
            _buildFeatureItem('Field Conditions', 'Planting and harvesting windows'),
            _buildFeatureItem('Crop-Specific Weather', 'Weather data tailored to specific crops'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.spacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: UIConstants.spacingSmall,
            height: UIConstants.spacingSmall,
            margin: const EdgeInsets.only(top: UIConstants.spacingMedium),
            decoration: BoxDecoration(
              color: AppTheme.textMedium,
              borderRadius: BorderRadius.circular(UIConstants.spacingTiny),
            ),
          ),
          const SizedBox(width: UIConstants.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyBold,
                ),
                Text(
                  description,
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 