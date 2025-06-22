import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sd_city.dart';
import '../providers/weather_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/location_error_dialog.dart';
import '../screens/weather_screen.dart';
import '../screens/afd_screen.dart';
import '../screens/spc_outlooks_screen.dart';
import '../screens/radar_screen.dart';
import '../screens/almanac_screen.dart';
import '../config/navigation_config.dart';

class MainAppContainer extends StatefulWidget {
  const MainAppContainer({super.key});

  @override
  State<MainAppContainer> createState() => _MainAppContainerState();
}

class _MainAppContainerState extends State<MainAppContainer> {
  int _currentIndex = 0; // Track current screen

  /// Handle navigation to a specific screen index
  void _handleNavigation(int index) {
    if (index >= 0 && index < NavigationConfig.items.length) {
      setState(() => _currentIndex = index);
    }
  }

  Widget _buildCitySelector(BuildContext context) {
    // Access the providers
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final selectedCity = weatherProvider.selectedCity;
    final isUsingLocation = weatherProvider.isUsingLocation;
    final isLoading = locationProvider.isLoading;
    final isUsingCachedLocation = locationProvider.isUsingCachedLocation;
    final cacheStatusMessage = locationProvider.cacheStatusMessage;

    return GestureDetector(
      onTap: isLoading ? null : () async {
        // Create location option with cache status
        final locationOption = Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: isUsingLocation
                ? BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.my_location,
                    color: Colors.white70,
                    size: 20,
                  ),
                  title: Text(
                    "Use My Location",
                    style: AppTheme.bodyLarge.copyWith(
                      color: isUsingLocation ? Colors.white : AppTheme.textLight,
                      fontWeight: isUsingLocation ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isUsingLocation && isUsingCachedLocation
                      ? IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                          onPressed: () async {
                            Navigator.of(context).pop('refresh');
                          },
                          tooltip: 'Refresh location',
                        )
                      : null,
                  onTap: () async {
                    if (mounted) {
                      Navigator.of(context).pop('location');
                    }
                  },
                ),
                // Show cache status if using cached location
                if (isUsingLocation && isUsingCachedLocation && cacheStatusMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      cacheStatusMessage,
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

        // Create divider
        final divider = Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: 1,
          color: Colors.white24,
        );

        // Create city items
        final List<Widget> cityItems = SDCities.allCities.map((city) {
          final bool isSelected = city.name == selectedCity.name && !isUsingLocation;
          return Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: isSelected
                  ? BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(16),
                    )
                  : null,
              child: ListTile(
                title: Text(
                  "${city.name}, SD",
                  style: AppTheme.bodyLarge.copyWith(
                    color: isSelected ? Colors.white : AppTheme.textLight,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  if (mounted) {
                    Navigator.of(context).pop(city);
                  }
                },
              ),
            ),
          );
        }).toList();

        // Combine all items
        final allItems = [locationOption, divider, ...cityItems];

        final dynamic selected = await showModalBottomSheet<dynamic>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: GlassCard(
                useBlur: true,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: allItems,
                  ),
                ),
              ),
            );
          },
        );

        if (selected != null) {
          if (selected == 'location') {
            // Handle location selection
            if (mounted) {
              // ignore: use_build_context_synchronously
              final success = await Provider.of<WeatherProvider>(context, listen: false).fetchWeatherForLocation();
              if (!success) {
                // Show error message if location failed
                if (mounted) {
                  showLocationErrorDialog(
                    context: context,
                    errorType: locationProvider.errorType ?? LocationErrorType.unknown,
                    message: locationProvider.userFriendlyErrorMessage,
                    onRetry: () async {
                      final retrySuccess = await Provider.of<WeatherProvider>(context, listen: false).fetchWeatherForLocation();
                      if (!retrySuccess && mounted) {
                        showLocationErrorDialog(
                          context: context,
                          errorType: locationProvider.errorType ?? LocationErrorType.unknown,
                          message: locationProvider.userFriendlyErrorMessage,
                        );
                      }
                    },
                  );
                }
              }
            }
          } else if (selected == 'refresh') {
            // Handle location refresh
            if (mounted) {
              // ignore: use_build_context_synchronously
              final success = await Provider.of<WeatherProvider>(context, listen: false).refreshLocationWeather();
              if (!success) {
                // Show error message if refresh failed
                if (mounted) {
                  showLocationErrorDialog(
                    context: context,
                    errorType: locationProvider.errorType ?? LocationErrorType.unknown,
                    message: locationProvider.userFriendlyErrorMessage,
                    onRetry: () async {
                      final retrySuccess = await Provider.of<WeatherProvider>(context, listen: false).refreshLocationWeather();
                      if (!retrySuccess && mounted) {
                        showLocationErrorDialog(
                          context: context,
                          errorType: locationProvider.errorType ?? LocationErrorType.unknown,
                          message: locationProvider.userFriendlyErrorMessage,
                        );
                      }
                    },
                  );
                }
              }
            }
          } else if (selected is SDCity && selected.name != selectedCity.name) {
            // Handle city selection
            if (mounted) {
              // ignore: use_build_context_synchronously
              Provider.of<WeatherProvider>(context, listen: false).setSelectedCity(selected);
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF), // 10% white
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x33FFFFFF)), // 20% white
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.loadingIndicatorColor),
                ),
              )
            else
              Icon(
                isUsingLocation ? Icons.my_location : Icons.location_on,
                color: Colors.white70,
                size: 14,
              ),
            const SizedBox(width: 3),
            Text(
              isLoading ? "Getting Location..." : (isUsingLocation ? "Your Location" : selectedCity.name),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(width: 3),
            if (!isLoading)
              const Icon(Icons.expand_more, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final citySelectorWidget = _buildCitySelector(context);

    // IndexedStack is more performant for switching between a fixed number of screens
    // as it keeps the state of inactive screens alive.
    return IndexedStack(
      index: _currentIndex,
      children: [
        WeatherPageWrapper(
          citySelector: citySelectorWidget,
          onNavigate: _handleNavigation,
        ),
        RadarScreenWrapper(
          citySelector: citySelectorWidget,
          onNavigate: _handleNavigation,
        ),
        AFDScreenWrapper(
          citySelector: citySelectorWidget,
          onNavigate: _handleNavigation,
        ),
        SpcOutlooksScreenWrapper(
          citySelector: citySelectorWidget,
          onNavigate: _handleNavigation,
        ),
        AlmanacScreenWrapper(
          citySelector: citySelectorWidget,
          onNavigate: _handleNavigation,
        ),
      ],
    );
  }
}

// Wrapper classes for each screen
class WeatherPageWrapper extends StatelessWidget {
  final Widget citySelector;
  final Function(int) onNavigate;

  const WeatherPageWrapper({
    super.key,
    required this.citySelector,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    // WeatherPage will now get its data directly from the provider.
    return WeatherPage(
      citySelector: citySelector,
      onNavigate: onNavigate,
      currentScreenId: 'weather',
    );
  }
}

class AFDScreenWrapper extends StatelessWidget {
  final Widget citySelector;
  final Function(int) onNavigate;

  const AFDScreenWrapper({
    super.key,
    required this.citySelector,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    final condition = weatherProvider.weatherData?.currentConditions?.textDescription;
    final gradient = AppTheme.getGradientForCondition(condition);

    return AFDScreen(
      citySelector: citySelector,
      onNavigate: onNavigate,
      gradientColors: gradient,
      currentScreenId: 'afd',
    );
  }
}

class SpcOutlooksScreenWrapper extends StatelessWidget {
  final Widget citySelector;
  final Function(int) onNavigate;

  const SpcOutlooksScreenWrapper({
    super.key,
    required this.citySelector,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return SpcOutlooksScreen(
      citySelector: citySelector,
      onNavigate: onNavigate,
      currentScreenId: 'spc_outlooks',
    );
  }
}

class RadarScreenWrapper extends StatelessWidget {
  final Widget citySelector;
  final Function(int) onNavigate;

  const RadarScreenWrapper({
    super.key,
    required this.citySelector,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    // This wrapper no longer needs to know about the city.
    // The RadarPage will get it from the provider.
    return RadarPage(
      citySelector: citySelector,
      onNavigate: onNavigate,
      currentScreenId: 'radar',
    );
  }
}

class AlmanacScreenWrapper extends StatelessWidget {
  final Widget citySelector;
  final Function(int) onNavigate;

  const AlmanacScreenWrapper({
    super.key,
    required this.citySelector,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return AlmanacScreen(
      citySelector: citySelector,
      onNavigate: onNavigate,
      currentScreenId: 'almanac',
    );
  }
}
