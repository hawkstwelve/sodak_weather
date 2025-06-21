import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass/frosted_background.dart';
import '../widgets/glass/glass_card.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../models/sd_city.dart';
import '../models/spc_outlook.dart';
import '../providers/weather_provider.dart';
import '../services/spc_outlook_service.dart';

class SpcOutlooksScreen extends StatefulWidget {
  final Widget? citySelector;
  final Function(int)? onNavigate;

  const SpcOutlooksScreen({
    super.key,
    this.citySelector,
    this.onNavigate,
  });

  @override
  State<SpcOutlooksScreen> createState() => _SpcOutlooksScreenState();
}

class _SpcOutlooksScreenState extends State<SpcOutlooksScreen> {
  Future<List<SpcOutlook>>? _futureData;
  List<bool> _expanded = [false, false, false];
  SDCity? _lastFetchedCity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentCity = Provider.of<WeatherProvider>(context).selectedCity;
    
    if (_lastFetchedCity == null || _lastFetchedCity!.name != currentCity.name) {
      _lastFetchedCity = currentCity;
      // Force a refresh by clearing cache and re-fetching
      SpcOutlookService.clearSpcCache().then((_) {
        if (mounted) {
          setState(() {
            _futureData = SpcOutlookService.fetchAllOutlooks();
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get provider for city and gradient data
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final selectedCity = weatherProvider.selectedCity;
    final condition = weatherProvider.weatherData?.currentConditions?.textDescription;
    final gradientColors = AppTheme.getGradientForCondition(condition);

    return FrostedPageScaffold(
      gradientColors: gradientColors,
      appBar: AppBar(
        title: const Text(
          'Storm Outlooks',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textLight,
        elevation: 0,
        titleSpacing: NavigationToolbar.kMiddleSpacing,
        actions: [
          if (widget.citySelector != null) widget.citySelector!,
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(
        gradientColors: gradientColors,
        selectedCity: selectedCity,
        currentScreen: 'spc_outlooks',
        onWeatherTap: () {
          Navigator.pop(context);
          widget.onNavigate?.call(0);
        },
        onAfdTap: () {
          Navigator.pop(context);
          widget.onNavigate?.call(1);
        },
        onSpcOutlooksTap: () {
          Navigator.pop(context);
        },
        onRadarTap: () {
          Navigator.pop(context);
          widget.onNavigate?.call(3);
        },
      ),
      body: _futureData == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<SpcOutlook>>(
              future: _futureData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading SPC Outlooks: ${snapshot.error}',
                      style: AppTheme.bodyMedium,
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No data available',
                      style: AppTheme.bodyMedium,
                    ),
                  );
                }
                final data = snapshot.data!;
                if (_expanded.length != data.length) {
                  _expanded = List.generate(data.length, (_) => false);
                }
                return ListView.builder(
                  itemCount: data.length,
                  cacheExtent: 1000,
                  itemBuilder: (context, idx) {
                    final outlook = data[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 16.0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _expanded[idx] = !_expanded[idx];
                          });
                        },
                        child: GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Day ${outlook.day} Outlook',
                                  style: AppTheme.headingMedium,
                                ),
                                const SizedBox(height: 8),
                                Image.network(
                                  outlook.imgUrl,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(child: Icon(Icons.error));
                                  },
                                ),
                                if (_expanded[idx])
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: Text(
                                      outlook.discussion,
                                      style: AppTheme.bodyMedium,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
