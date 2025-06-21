import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/sd_city.dart';

class AppDrawer extends StatelessWidget {
  final List<Color> gradientColors;
  final SDCity selectedCity;
  final VoidCallback onWeatherTap;
  final VoidCallback onAfdTap;
  final VoidCallback onSpcOutlooksTap;
  final VoidCallback? onRadarTap;
  final String currentScreen;

  const AppDrawer({
    Key? key,
    required this.gradientColors,
    required this.selectedCity,
    required this.onWeatherTap,
    required this.onAfdTap,
    required this.onSpcOutlooksTap,
    this.onRadarTap,
    required this.currentScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Using RepaintBoundary to isolate complex painting operations
    return RepaintBoundary(
      child: Drawer(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
          child: Column(
            // Using Column instead of ListView for better performance
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with image background and text (no extra top space)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: const DecorationImage(
                          image: AssetImage('assets/drawer_background.png'),
                          fit: BoxFit.cover,
                          opacity: 0.7,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        'Sodak Weather',
                        style: TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Divider line
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(color: Colors.white70, thickness: 1.2),
              ),
              const SizedBox(height: 8),
              // Continue with the rest of your drawer items
              // Use optimized navigation items
              _buildNavigationItem(
                context,
                'Weather',
                Icons.cloud,
                currentScreen == 'weather',
                onWeatherTap,
              ),
              _buildNavigationItem(
                context,
                'Area Forecast Discussion',
                Icons.article,
                currentScreen == 'afd',
                onAfdTap,
              ),
              _buildNavigationItem(
                context,
                'Storm Outlooks',
                Icons.warning,
                currentScreen == 'spc_outlooks',
                onSpcOutlooksTap,
              ),
              _buildNavigationItem(
                context,
                'Radar',
                Icons.radar,
                currentScreen == 'radar',
                onRadarTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Optimized navigation item with simpler rendering
  Widget _buildNavigationItem(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback? onTap,
  ) {
    // Use a simpler container instead of GlassCard for menu items
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Material(
        color: isSelected
            ? const Color(0x33FFFFFF)
            : Colors.transparent, // 20% opacity white
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.textLight),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 16,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
