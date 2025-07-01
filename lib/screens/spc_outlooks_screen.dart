import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass/glass_card.dart';
import '../theme/app_theme.dart';
import '../models/sd_city.dart';
import '../models/spc_outlook.dart';
import '../providers/weather_provider.dart';
import '../services/spc_outlook_service.dart';
import '../constants/ui_constants.dart';

class SpcOutlooksScreen extends StatefulWidget {
  final Widget? citySelector;
  final Function(int)? onNavigate;
  final String currentScreenId;

  const SpcOutlooksScreen({
    super.key,
    this.citySelector,
    this.onNavigate,
    required this.currentScreenId,
  });

  @override
  State<SpcOutlooksScreen> createState() => _SpcOutlooksScreenState();
}

class _SpcOutlooksScreenState extends State<SpcOutlooksScreen> {
  Future<List<SpcOutlook>>? _futureData;
  final List<bool> _expanded = [false, false, false];
  SDCity? _lastFetchedCity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentCity = Provider.of<WeatherProvider>(context).selectedCity;
    
    if (_lastFetchedCity == null || _lastFetchedCity!.name != currentCity.name) {
      _lastFetchedCity = currentCity;
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    // Force a refresh by clearing cache and re-fetching
    await SpcOutlookService.clearSpcCache();
    if (mounted) {
      setState(() {
        _futureData = SpcOutlookService.fetchAllOutlooks();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get provider for city and gradient data
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final condition = weatherProvider.weatherData?.currentConditions?.textDescription;
    final gradientColors = AppTheme.getGradientForCondition(condition);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<List<SpcOutlook>>(
          future: _futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.loadingIndicatorColor));
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(UIConstants.spacingXLarge),
                  child: Text(
                    'Error loading outlooks: ${snapshot.error}',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return Center(
                child: Text(
                  'No outlooks available.',
                  style: AppTheme.bodyMedium,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, idx) {
                  final outlook = data[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: UIConstants.spacingLarge,
                      horizontal: UIConstants.spacingXLarge,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _expanded[idx] = !_expanded[idx];
                        });
                      },
                      child: GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(UIConstants.spacingXLarge),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Day ${outlook.day} Outlook',
                                      style: AppTheme.headingSmall,
                                    ),
                                  ),
                                  Icon(
                                    _expanded[idx] ? Icons.expand_less : Icons.expand_more,
                                    color: AppTheme.textLight,
                                  ),
                                ],
                              ),
                              const SizedBox(height: UIConstants.spacingStandard),
                              Image.network(
                                outlook.imgUrl,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(child: CircularProgressIndicator(color: AppTheme.loadingIndicatorColor));
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(child: Icon(Icons.error));
                                },
                              ),
                              if (_expanded[idx]) ...[
                                const SizedBox(height: UIConstants.spacingXLarge),
                                Text(
                                  outlook.discussion,
                                  style: AppTheme.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
