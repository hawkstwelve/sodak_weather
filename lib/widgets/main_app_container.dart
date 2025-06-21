import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sd_city.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass/glass_card.dart';
import '../screens/weather_screen.dart';
import '../screens/afd_screen.dart';
import '../screens/spc_outlooks_screen.dart';
import '../screens/radar_screen.dart';

class MainAppContainer extends StatefulWidget {
  const MainAppContainer({super.key});

  @override
  State<MainAppContainer> createState() => _MainAppContainerState();
}

class _MainAppContainerState extends State<MainAppContainer> {
  int _currentIndex = 0; // Track current screen

  Widget _buildCitySelector(BuildContext context) {
    // Access the provider
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final selectedCity = weatherProvider.selectedCity;

    return GestureDetector(
      onTap: () async {
        final List<Widget> cityItems = SDCities.allCities.map((city) {
          final bool isSelected = city.name == selectedCity.name;
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

        final SDCity? selected = await showModalBottomSheet<SDCity>(
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
                    children: cityItems,
                  ),
                ),
              ),
            );
          },
        );

        if (selected != null && selected.name != selectedCity.name) {
          // Use the provider to update the city
          if (mounted) {
            // ignore: use_build_context_synchronously
            Provider.of<WeatherProvider>(context, listen: false).setSelectedCity(selected);
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
            const Icon(Icons.location_on, color: Colors.white70, size: 14),
            const SizedBox(width: 3),
            Text(
              selectedCity.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(width: 3),
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
          onNavigate: (index) => setState(() => _currentIndex = index),
        ),
        AFDScreenWrapper(
          citySelector: citySelectorWidget,
          onNavigate: (index) => setState(() => _currentIndex = index),
        ),
        SpcOutlooksScreenWrapper(
          citySelector: citySelectorWidget,
          onNavigate: (index) => setState(() => _currentIndex = index),
        ),
        RadarScreenWrapper(
          citySelector: citySelectorWidget,
          onNavigate: (index) => setState(() => _currentIndex = index),
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
    );
  }
}
