import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/weather_screen.dart';
import '../screens/radar_screen.dart';
import '../screens/afd_screen.dart';
import '../screens/spc_outlooks_screen.dart';
import '../screens/almanac_screen.dart';
import '../screens/agriculture_screen.dart';
import '../screens/weather_chat_screen.dart';
import '../screens/settings_screen.dart';
import '../providers/weather_provider.dart';
import '../providers/location_provider.dart';
import '../providers/theme_provider.dart';
// import '../theme/app_theme.dart';
import '../models/sd_city.dart';
import '../widgets/location_error_dialog.dart';
import '../config/navigation_config.dart';
import '../constants/ui_constants.dart';
import 'background/frosted_blob_background.dart';
import 'custom_navigation_drawer.dart';

class MainAppContainer extends StatefulWidget {
  const MainAppContainer({super.key});

  @override
  State<MainAppContainer> createState() => _MainAppContainerState();
}

class _MainAppContainerState extends State<MainAppContainer> {
  int _currentIndex = 0;
  bool _isDrawerOpen = false;

  void _handleNavigation(int index) {
    if (index >= 0 && index < NavigationConfig.items.length) {
      setState(() => _currentIndex = index);
      _closeDrawer();
    }
  }

  void _openDrawer() {
    setState(() => _isDrawerOpen = true);
  }

  void _closeDrawer() {
    setState(() => _isDrawerOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Consumer2<WeatherProvider, LocationProvider>(
      builder: (context, weatherProvider, locationProvider, child) {
        // Show loading state if providers are not properly initialized
        // Check both selectedCity and if the providers have been set up
        if (weatherProvider.isLoading || !weatherProvider.isInitialized) {
          return FrostedBlobBackground(
            themeConfig: themeProvider.config,
            child: Scaffold(
              extendBodyBehindAppBar: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing weather data...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return FrostedBlobBackground(
          themeConfig: themeProvider.config,
          child: Stack(
            children: [
              // Main content
              Scaffold(
                extendBodyBehindAppBar: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  elevation: 0,
                  title: Text(
                    _getCurrentPageTitle(weatherProvider),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    _buildCitySelector(context),
                    const SizedBox(width: UIConstants.spacingStandard),
                  ],
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: _openDrawer,
                  ),
                ),
                body: _buildBody(),
              ),

              // Light frosted drawer + scrim (self-contained)
              CustomNavigationDrawer(
                selectedIndex: _currentIndex,
                onNavigationChanged: _handleNavigation,
                isOpen: _isDrawerOpen,
                onClose: _closeDrawer,
              ),
            ],
          ),
        );
      },
    );
  }

  String _getCurrentPageTitle(WeatherProvider weatherProvider) {
    final currentItem = NavigationConfig.getItemByIndex(_currentIndex);
    if (currentItem?.screenId == 'weather') {
      if (weatherProvider.isUsingLocation) {
        return 'Current Location Weather';
      } else {
        // Add null safety check for selectedCity
        final cityName = weatherProvider.selectedCity.name;
        return '$cityName Weather';
      }
    } else if (currentItem?.screenId == 'weather_chat') {
      return 'AI Weather Chat';
    }
    return currentItem?.title ?? 'Sodak Weather';
  }

  Widget _buildBody() {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        // Don't render body if weather provider is not ready
        final citySelectorWidget = _buildCitySelector(context);

        return AnimatedSwitcher(
          duration: UIConstants.pageTransition,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: IndexedStack(
            key: ValueKey(_currentIndex),
            index: _currentIndex,
            children: [
              WeatherPage(
                citySelector: citySelectorWidget,
                onNavigate: _handleNavigation,
                currentScreenId: 'weather',
              ),
              RadarPage(
                citySelector: citySelectorWidget,
                onNavigate: _handleNavigation,
                currentScreenId: 'radar',
              ),
              AFDScreen(
                citySelector: citySelectorWidget,
                onNavigate: _handleNavigation,
                currentScreenId: 'afd',
              ),
              SpcOutlooksScreen(
                citySelector: citySelectorWidget,
                onNavigate: _handleNavigation,
                currentScreenId: 'spc_outlooks',
              ),
              AlmanacScreen(
                citySelector: citySelectorWidget,
                onNavigate: _handleNavigation,
                currentScreenId: 'almanac',
              ),
              AgricultureScreen(
                citySelector: citySelectorWidget,
                onNavigate: _handleNavigation,
                currentScreenId: 'agriculture',
              ),
              const WeatherChatScreen(),
              SettingsScreen(onNavigate: _handleNavigation),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCitySelector(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        return Consumer<LocationProvider>(
          builder: (context, locationProvider, child) {
            return GestureDetector(
              onTap: () => _showCitySelector(context, weatherProvider, locationProvider),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    weatherProvider.isUsingLocation ? Icons.my_location : Icons.location_on,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: 18,
                  ),
                  const SizedBox(width: UIConstants.spacingSmall),
                  Text(
                    weatherProvider.isUsingLocation 
                        ? 'Current Location'
                        : weatherProvider.selectedCity.name,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: UIConstants.spacingSmall),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: 20,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  void _showCitySelector(BuildContext context, WeatherProvider weatherProvider, LocationProvider locationProvider) {
    // Safety check - don't show selector if providers are not ready
    final RenderBox button = context.findRenderObject() as RenderBox;
    final buttonPosition = button.localToGlobal(Offset.zero);
    final buttonSize = button.size;
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate optimal position for the dropdown
    final dropdownWidth = (screenSize.width * 0.8).clamp(280.0, 320.0);
    final dropdownHeight = 400.0; // Approximate height for the city list
    
    // Start with right-aligned positioning (default)
    double left = buttonPosition.dx + buttonSize.width - dropdownWidth;
    double top = buttonPosition.dy + buttonSize.height + 2; // Reduced from 8 to 2 for tighter connection
    
    // Ensure dropdown doesn't go off the left edge
    if (left < 16) {
      left = 16;
    }
    
    // Ensure dropdown doesn't go off the right edge
    if (left + dropdownWidth > screenSize.width - 16) {
      left = screenSize.width - dropdownWidth - 16;
    }
    
    // Ensure dropdown doesn't go off the bottom edge
    if (top + dropdownHeight > screenSize.height - 16) {
      top = buttonPosition.dy - dropdownHeight - 2; // Reduced from 8 to 2 for tighter connection
    }
    
    // Ensure dropdown doesn't go off the top edge
    if (top < 16) {
      top = 16;
    }
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => _CitySelectorDialog(
        weatherProvider: weatherProvider,
        locationProvider: locationProvider,
        position: Offset(left, top),
      ),
    );
  }

}

class _CitySelectorDialog extends StatelessWidget {
  final WeatherProvider weatherProvider;
  final LocationProvider locationProvider;
  final Offset position;

  const _CitySelectorDialog({
    required this.weatherProvider,
    required this.locationProvider,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full screen tap to close
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),
        ),
        // Positioned city selector
        Positioned(
          left: position.dx,
          top: position.dy,
          child: _CitySelectorPanel(
            weatherProvider: weatherProvider,
            locationProvider: locationProvider,
          ),
        ),
      ],
    );
  }
}

class _CitySelectorPanel extends StatelessWidget {
  final WeatherProvider weatherProvider;
  final LocationProvider locationProvider;

  const _CitySelectorPanel({
    required this.weatherProvider,
    required this.locationProvider,
  });

  @override
  Widget build(BuildContext context) {
    final radius = UIConstants.borderRadiusStandard;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Make dropdown width responsive to screen size
    final dropdownWidth = (screenWidth * 0.8).clamp(280.0, 320.0);

    return Container(
      width: dropdownWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.white.withValues(alpha: 0.35), // Increased from 0.22 to 0.35 for more frosted appearance
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusStandard),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color.fromRGBO(0, 0, 0, 0.08),
              Color.fromRGBO(0, 0, 0, 0.03),
              Color.fromRGBO(0, 0, 0, 0.00),
            ],
            stops: [0.0, 0.45, 0.80],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingLarge),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current location option
            _buildCityMenuItem(
              context: context,
              icon: Icons.my_location,
              title: 'Use Current Location',
              isSelected: weatherProvider.isUsingLocation,
              onTap: () async {
                Navigator.of(context).pop();
                await _handleCurrentLocationSelection(context, locationProvider, weatherProvider);
              },
            ),
            // Divider
            if (weatherProvider.isUsingLocation && locationProvider.isUsingCachedLocation)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            // City options
            ...SDCities.allCities.map((city) {
              final isSelected = city.name == (weatherProvider.selectedCity.name) && !weatherProvider.isUsingLocation;
              return _buildCityMenuItem(
                context: context,
                icon: Icons.location_on,
                title: '${city.name}, SD',
                isSelected: isSelected,
                onTap: () {
                  Navigator.of(context).pop();
                  weatherProvider.setSelectedCity(city);
                },
                showIcon: false,
              );
            }),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildCityMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool showIcon = true,
  }) {
    final radius = UIConstants.borderRadiusStandard;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: UIConstants.spacingTiny),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: Theme.of(context).colorScheme.secondary.withValues(alpha: UIConstants.opacityVeryLow),
          highlightColor: Theme.of(context).colorScheme.secondary.withValues(alpha: UIConstants.opacityVeryLow),
          child: AnimatedContainer(
            duration: UIConstants.animationFast,
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacingLarge,
              vertical: UIConstants.spacingStandard,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.transparent,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.60),
                      width: 1,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.white.withValues(alpha: 0.92),
                ),
                const SizedBox(width: UIConstants.spacingLarge),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.white.withValues(alpha: 0.92),
                        ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCurrentLocationSelection(
    BuildContext context, 
    LocationProvider locationProvider, 
    WeatherProvider weatherProvider
  ) async {
    // Safety check - don't proceed if providers are not ready
    try {
      // Get current location
      final success = await locationProvider.getCurrentLocation();
      
      if (success && locationProvider.currentLocation != null) {
        // Successfully got location, now fetch weather data directly
        await weatherProvider.fetchAllWeatherDataForCoordinates(
          locationProvider.currentLocation!.latitude,
          locationProvider.currentLocation!.longitude,
        );
        
        // Set the weather provider to use location without fetching location again
        weatherProvider.setUsingLocation(true);
        
        // Show success feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location updated to current location'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        // Show error dialog with proper error type
        if (context.mounted) {
          showDialog(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.45),
            builder: (context) => LocationErrorDialog(
              errorType: locationProvider.errorType ?? LocationErrorType.unknown,
              message: locationProvider.errorMessage ?? 'Failed to get current location.',
            ),
          );
        }
      }
    } catch (e) {
      // Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.45),
          builder: (context) => LocationErrorDialog(
            errorType: LocationErrorType.unknown,
            message: 'Error getting location: $e',
          ),
        );
      }
    }
  }


}

