import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidebarx/sidebarx.dart';
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
import '../theme/app_theme.dart';
import '../models/sd_city.dart';
import '../widgets/location_error_dialog.dart';
import '../config/navigation_config.dart';
import '../constants/ui_constants.dart';

class MainAppContainer extends StatefulWidget {
  const MainAppContainer({super.key});

  @override
  State<MainAppContainer> createState() => _MainAppContainerState();
}

class _MainAppContainerState extends State<MainAppContainer> {
  int _currentIndex = 0;
  final SidebarXController _sidebarXController = SidebarXController(selectedIndex: 0, extended: false);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _handleNavigation(int index) {
    if (index >= 0 && index < NavigationConfig.items.length) {
      setState(() => _currentIndex = index);
      _sidebarXController.selectIndex(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, _) {
        final condition = weatherProvider.weatherData?.currentConditions?.textDescription;
        final gradient = AppTheme.getGradientForCondition(condition);
        
        return Scaffold(
          key: _scaffoldKey,
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          drawer: SidebarX(
            controller: _sidebarXController,
            theme: SidebarXTheme(
              width: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradient,
                ),
                backgroundBlendMode: BlendMode.srcOver,
              ),
              iconTheme: IconThemeData(color: Colors.white.withValues(alpha: UIConstants.opacityHigh), size: 20),
              selectedIconTheme: const IconThemeData(color: Colors.white, size: 20),
              textStyle: TextStyle(color: Colors.white.withValues(alpha: UIConstants.opacityHigh)),
              selectedTextStyle: const TextStyle(color: Colors.white),
              itemDecoration: const BoxDecoration(),
              selectedItemDecoration: BoxDecoration(
                color: Colors.white.withValues(alpha: UIConstants.opacityLow),
                borderRadius: BorderRadius.circular(UIConstants.spacingXLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
                    blurRadius: UIConstants.spacingXLarge,
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: UIConstants.opacityLow)),
              ),
            ),
            extendedTheme: SidebarXTheme(
              width: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradient,
                ),
                backgroundBlendMode: BlendMode.srcOver,
              ),
              textStyle: TextStyle(color: Colors.white.withValues(alpha: UIConstants.opacityHigh)),
              selectedTextStyle: const TextStyle(color: Colors.white),
              itemTextPadding: const EdgeInsets.only(left: UIConstants.spacingLarge, top: 0),
              selectedItemTextPadding: const EdgeInsets.only(left: UIConstants.spacingLarge, top: 0),
              itemDecoration: const BoxDecoration(),
              selectedItemDecoration: BoxDecoration(
                color: Colors.white.withValues(alpha: UIConstants.opacityLow),
                borderRadius: BorderRadius.circular(UIConstants.spacingXLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: UIConstants.opacityLow),
                    blurRadius: UIConstants.spacingXLarge,
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: UIConstants.opacityLow)),
              ),
            ),
            headerBuilder: (context, extended) {
              if (extended) {
                // Full header for expanded state
                return Container(
                  padding: const EdgeInsets.fromLTRB(UIConstants.spacingXLarge, UIConstants.spacingXLarge, UIConstants.spacingXLarge, 0),
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
                            opacity: UIConstants.opacityHigh,
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
                );
              } else {
                // No header for collapsed state
                return const SizedBox.shrink();
              }
            },
            items: NavigationConfig.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return SidebarXItem(
                icon: item.icon,
                label: item.title,
                onTap: () {
                  Navigator.of(context).pop(); // Close the drawer
                  _handleNavigation(index);
                },
              );
            }).toList(),
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: AppTheme.textLight,
            elevation: 0,
            title: Text(_getCurrentPageTitle()),
            actions: [
              _buildCitySelector(context),
              const SizedBox(width: UIConstants.spacingStandard),
            ],
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                _sidebarXController.setExtended(false); // Start collapsed
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),
          body: _buildBody(),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Listen to sidebar selection changes
    _sidebarXController.addListener(() {
      final selectedIndex = _sidebarXController.selectedIndex;
      if (selectedIndex != _currentIndex) {
        _handleNavigation(selectedIndex);
      }
    });
  }

  String _getCurrentPageTitle() {
    final currentItem = NavigationConfig.getItemByIndex(_currentIndex);
    if (currentItem?.screenId == 'weather') {
      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
      return '${weatherProvider.selectedCity.name} Weather';
    } else if (currentItem?.screenId == 'weather_chat') {
      return 'AI Weather Chat';
    }
    return currentItem?.title ?? 'Sodak Weather';
  }

  Widget _buildBody() {
    final citySelectorWidget = _buildCitySelector(context);
    
    return IndexedStack(
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
    );
  }

  Widget _buildCitySelector(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, _) {
        return Consumer<LocationProvider>(
          builder: (context, locationProvider, _) {
            final selectedCity = weatherProvider.selectedCity;
            final isUsingLocation = weatherProvider.isUsingLocation;
            final isLoading = locationProvider.isLoading;

            return GestureDetector(
              onTap: isLoading ? null : () => _showCitySelectorDropdown(context, weatherProvider, locationProvider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x33FFFFFF)),
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
          },
        );
      },
    );
  }

  void _showCitySelectorDropdown(BuildContext context, WeatherProvider weatherProvider, LocationProvider locationProvider) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
    final screenWidth = MediaQuery.of(context).size.width;
    const dropdownWidth = 250.0; // Max width of dropdown
    
    // Calculate left position to keep dropdown within screen bounds
    double leftPosition = buttonPosition.dx;
    if (leftPosition + dropdownWidth > screenWidth) {
      leftPosition = screenWidth - dropdownWidth - 16; // 16px margin from right edge
    }
    if (leftPosition < 16) {
      leftPosition = 16; // 16px margin from left edge
    }
    
    OverlayEntry? overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent overlay to catch taps outside the dropdown
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                overlayEntry?.remove();
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // The actual dropdown
          Positioned(
            left: leftPosition,
            top: buttonPosition.dy + button.size.height + 8,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {
                  // This prevents taps on the dropdown background from closing it
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.8), // Dark background for better contrast
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)), // Subtle white border
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 200,
                      maxWidth: 250,
                      maxHeight: 400,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Location option
                          _buildMenuItem(
                            context: context,
                            icon: Icons.my_location,
                            title: 'Use My Location',
                            isSelected: weatherProvider.isUsingLocation,
                            onTap: () async {
                              overlayEntry?.remove();
                              final success = await weatherProvider.fetchWeatherForLocation();
                              if (!context.mounted) return;
                              if (!success) {
                                showLocationErrorDialog(
                                  context: context,
                                  errorType: locationProvider.errorType ?? LocationErrorType.unknown,
                                  message: locationProvider.userFriendlyErrorMessage,
                                  onRetry: () async {
                                    final retrySuccess = await weatherProvider.fetchWeatherForLocation();
                                    if (!context.mounted) return;
                                    if (!retrySuccess) {
                                      showLocationErrorDialog(
                                        context: context,
                                        errorType: locationProvider.errorType ?? LocationErrorType.unknown,
                                        message: locationProvider.userFriendlyErrorMessage,
                                      );
                                    }
                                  },
                                );
                              }
                            },
                            showIcon: false,
                          ),
                          
                          // Refresh option if using location
                          if (weatherProvider.isUsingLocation && locationProvider.isUsingCachedLocation)
                            _buildMenuItem(
                              context: context,
                              icon: Icons.refresh,
                              title: 'Refresh Location',
                              isSelected: false,
                              onTap: () async {
                                overlayEntry?.remove();
                                final success = await weatherProvider.refreshLocationWeather();
                                if (!context.mounted) return;
                                if (!success) {
                                  showLocationErrorDialog(
                                    context: context,
                                    errorType: locationProvider.errorType ?? LocationErrorType.unknown,
                                    message: locationProvider.userFriendlyErrorMessage,
                                    onRetry: () async {
                                      final retrySuccess = await weatherProvider.refreshLocationWeather();
                                      if (!context.mounted) return;
                                      if (!retrySuccess) {
                                        showLocationErrorDialog(
                                          context: context,
                                          errorType: locationProvider.errorType ?? LocationErrorType.unknown,
                                          message: locationProvider.userFriendlyErrorMessage,
                                        );
                                      }
                                    },
                                  );
                                }
                              },
                              indent: true,
                            ),
                          
                          // Divider
                          if (weatherProvider.isUsingLocation && locationProvider.isUsingCachedLocation)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              height: 1,
                              color: Colors.white24,
                            ),
                          
                          // City options
                          ...SDCities.allCities.map((city) {
                            final isSelected = city.name == weatherProvider.selectedCity.name && !weatherProvider.isUsingLocation;
                            return _buildMenuItem(
                              context: context,
                              icon: Icons.location_on,
                              title: '${city.name}, SD',
                              isSelected: isSelected,
                              onTap: () {
                                overlayEntry?.remove();
                                weatherProvider.setSelectedCity(city);
                              },
                              showIcon: false,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Add overlay entry
    Overlay.of(context).insert(overlayEntry);

    // Note: Menu items will handle closing the dropdown when tapped
    // No global tap detection needed as it interferes with menu item taps
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool indent = false,
    bool showIcon = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (indent) const SizedBox(width: 24),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: AppTheme.textLight,
                size: 16,
              ),
              const SizedBox(width: 8),
              if (showIcon)
                Icon(
                  icon,
                  color: AppTheme.textLight,
                  size: 16,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? AppTheme.textLight : AppTheme.textMedium,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
