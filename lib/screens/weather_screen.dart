import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weather_icons/weather_icons.dart';
import '../models/weather_data.dart';
import '../models/hourly_forecast.dart';
import '../models/sd_city.dart';
import '../models/nws_alert_model.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/daily_forecast_list_item.dart';
import '../widgets/hourly_forecast_list_item.dart';
import '../widgets/precipitation_chart.dart';
import '../utils/weather_utils.dart';
// import '../theme/app_theme.dart';
import '../widgets/nws_alert_banner.dart';
import '../screens/radar_screen.dart';
import '../widgets/radar_card.dart';


import '../providers/weather_provider.dart';
import '../constants/ui_constants.dart';

// Constants for styling and layout
const double kIconSizeLarge = UIConstants.iconSizeLarge * 2.5;
const double kIconSizeMedium = UIConstants.iconSizeLarge;
const double kIconSizeSmall = UIConstants.iconSizeMedium * 1.75;
const double kCardPadding = UIConstants.spacingLarge; // Reduced from spacingXXXLarge
const double kSpacingStandard = UIConstants.spacingLarge; // Reduced from spacingXLarge
const double kSpacingSmall = UIConstants.spacingStandard; // Reduced from spacingStandard
const double kForecastCardWidth = 110.0;
const double kForecastCardHeight = UIConstants.cardHeightMedium;
const double kHourlyForecastCardHeight = UIConstants.cardHeightLarge - 10;

class _CollapsibleDetailsCard extends StatefulWidget {
  const _CollapsibleDetailsCard();

  @override
  State<_CollapsibleDetailsCard> createState() => _CollapsibleDetailsCardState();
}

class _CollapsibleDetailsCardState extends State<_CollapsibleDetailsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: UIConstants.animationMedium,
      crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: GestureDetector(
        onTap: () => setState(() => _isExpanded = true),
        child: GlassCard(
          priority: GlassCardPriority.standard,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacingXXXLarge, // 24.0px - more left/right padding
            vertical: UIConstants.spacingLarge,    // 20.0px - keep top/bottom padding
          ), // Increased from spacingXLarge to properly align with other cards
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Conditions', style: Theme.of(context).textTheme.bodyLarge),
              Icon(Icons.expand_more, color: Theme.of(context).colorScheme.onSurface),
            ],
          ),
        ),
      ),
      secondChild: GestureDetector(
        onTap: () => setState(() => _isExpanded = false),
        child: _buildDetailsCard(context),
      ),
    );
  }
}

Widget _buildDetailsCard(BuildContext context) {
  return Selector<WeatherProvider, WeatherData>(
    selector: (context, provider) => provider.weatherData!,
    builder: (context, weatherData, child) {
      final conditions = weatherData.currentConditions!;
      final sunrise = weatherData.sunrise;
      final sunset = weatherData.sunset;
      return Selector<WeatherProvider, Map<String, dynamic>>(
        selector: (context, provider) => {
          'rain24hInches': provider.rain24hInches,
          'aqiCategory': provider.aqiCategory,
        },
        builder: (context, additionalData, child) {
          final items = [
            [
              _buildDetailItem(
                context,
                Builder(builder: (context) => BoxedIcon(WeatherIcons.humidity, color: Theme.of(context).colorScheme.onSurface, size: 28)),
                'Humidity',
                '${conditions.humidity ?? 'N/A'}%',
              ),
              _buildDetailItem(
                context,
                Builder(builder: (context) => BoxedIcon(WeatherIcons.thermometer, color: Theme.of(context).colorScheme.onSurface, size: 28)),
                'Dewpoint',
                conditions.dewpoint != null
                    ? '${conditions.dewpoint!.round()}°'
                    : 'N/A',
              ),
              _buildDetailItem(
                context,
                Builder(builder: (context) => BoxedIcon(WeatherIcons.rain, color: Theme.of(context).colorScheme.onSurface, size: 28)),
                'Rain (24h)',
                (additionalData['rain24hInches'] != null
                    ? '${additionalData['rain24hInches'].toStringAsFixed(2)} in'
                    : '0 in'),
              ),
              _buildDetailItem(
                context,
                Builder(builder: (context) => BoxedIcon(WeatherIcons.strong_wind, color: Theme.of(context).colorScheme.onSurface, size: 28)),
                'Wind',
                WeatherUtils.formatWind(
                  windDirection: conditions.windDirection,
                  windSpeedMph: conditions.windSpeedMph,
                  windGustMph: conditions.windGustMph,
                ),
              ),
            ],
            [
              _buildDetailItem(
                context,
                Builder(builder: (context) => BoxedIcon(WeatherIcons.hot, color: Theme.of(context).colorScheme.onSurface, size: 28)),
                'UV',
                WeatherUtils.uvIndexDescription(conditions.uvIndex),
              ),
              _buildDetailItem(
                context,
                Builder(builder: (context) => BoxedIcon(WeatherIcons.dust, color: Theme.of(context).colorScheme.onSurface, size: 28)),
                'AQI',
                _shortAqiCategory(additionalData['aqiCategory']) ?? 'N/A',
              ),
              _buildDetailItem(
                context,
                Builder(builder: (context) => BoxedIcon(WeatherIcons.sunrise, color: Theme.of(context).colorScheme.onSurface, size: 28)),
                'Sunrise',
                sunrise != null ? WeatherPage._timeFormatter.format(sunrise) : 'N/A',
              ),
              _buildDetailItem(
                context,
                Builder(builder: (context) => BoxedIcon(WeatherIcons.sunset, color: Theme.of(context).colorScheme.onSurface, size: 28)),
                'Sunset',
                sunset != null ? WeatherPage._timeFormatter.format(sunset) : 'N/A',
              ),
            ],
          ];
          return GlassCard(
            priority: GlassCardPriority.standard,
            child: Column(
              children: [
                for (int row = 0; row < 2; row++) ...[
                  Row(
                    children: [
                      for (int col = 0; col < 4; col++) ...[
                        Expanded(child: items[row][col]),
                        if (col < 3)
                          Container(
                            height: UIConstants.textFieldHeight,
                            width: UIConstants.dividerHeight,
                            color: const Color.fromRGBO(255, 255, 255, 0.12),
                            margin: const EdgeInsets.symmetric(vertical: UIConstants.spacingStandard), // Reduced from spacingStandard
                          ),
                      ],
                    ],
                  ),
                  if (row == 0)
                    Container(
                      height: UIConstants.dividerHeight,
                      color: const Color.fromRGBO(255, 255, 255, 0.12),
                      margin: const EdgeInsets.symmetric(vertical: UIConstants.spacingStandard), // Reduced from spacingStandard
                    ),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildDetailItem(BuildContext context, Widget icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacingTiny, vertical: UIConstants.spacingTiny),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(height: UIConstants.spacingSmall), // Reduced from spacingMedium
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: UIConstants.spacingTiny),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

String? _shortAqiCategory(String? category) {
  if (category == null) return null;
  final lower = category.toLowerCase();
  if (lower.contains('excellent')) return 'Excellent';
  if (lower.contains('good')) return 'Good';
  if (lower.contains('low')) return 'Low';
  if (lower.contains('moderate')) return 'Moderate';
  if (lower.contains('unhealthy for sensitive')) {
    return 'Unhealthy (Sensitive)';
  }
  if (lower.contains('unhealthy')) return 'Unhealthy';
  if (lower.contains('very unhealthy')) return 'Very Unhealthy';
  if (lower.contains('hazardous')) return 'Hazardous';
  return category;
}

class WeatherPage extends StatelessWidget {
  final Widget? citySelector;
  final Function(int)? onNavigate;
  final String currentScreenId;

  // Static DateFormat instances for performance optimization
  static final DateFormat _dateTimeFormatter = DateFormat('MMM d, h:mm a');
  static final DateFormat _timeFormatter = DateFormat('h:mm a');

  const WeatherPage({
    super.key,
    this.citySelector,
    this.onNavigate,
    required this.currentScreenId,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<WeatherProvider, String>(
      selector: (context, provider) => provider.selectedCity.name,
      builder: (context, cityName, child) {
        return Selector<WeatherProvider, String?>(
          selector: (context, provider) => provider.weatherData?.currentConditions?.textDescription,
          builder: (context, condition, child) {
            return SafeArea(child: _buildContent(context));
          },
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Selector<WeatherProvider, bool>(
      selector: (context, provider) => provider.isLoading,
      builder: (context, isLoading, child) {
        return Selector<WeatherProvider, WeatherData?>(
          selector: (context, provider) => provider.weatherData,
          builder: (context, weatherData, child) {
            if (isLoading) {
              return _buildLoadingIndicator();
            }

            return Selector<WeatherProvider, String?>(
              selector: (context, provider) => provider.errorMessage,
              builder: (context, errorMessage, child) {
                if (errorMessage != null) {
                  return _buildErrorWidget(context, errorMessage);
                }

                if (weatherData == null) {
                  return _buildNoDataWidget();
                }

                return _buildMainContent(context);
              },
            );
          },
        );
      },
    );
  }

  /// Builds the loading indicator widget with accent color
  Widget _buildLoadingIndicator() {
    return Builder(
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.secondary, // Uses accent color for loading
          strokeWidth: 3.0,
        ),
      ),
    );
  }

  /// Builds the error widget with retry functionality
  Widget _buildErrorWidget(BuildContext context, String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: UIConstants.iconSizeLarge, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: UIConstants.spacingXLarge),
          Builder(builder: (context) => Text('Error: $errorMessage', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium)),
          const SizedBox(height: UIConstants.spacingXLarge),
          ElevatedButton(
            onPressed: () => context.read<WeatherProvider>().fetchAllWeatherData(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Builds the no data available widget
  Widget _buildNoDataWidget() {
    return const Center(child: Text('No weather data available.'));
  }

  /// Builds the main scrollable content with all weather sections
  Widget _buildMainContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<WeatherProvider>().fetchAllWeatherData(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingLarge), // Reduced from spacingXLarge
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAlertsSection(context),
              const SizedBox(height: UIConstants.spacingLarge), // Reduced from spacingXLarge
              _buildCurrentConditionsCard(context),
              const SizedBox(height: UIConstants.spacingLarge), // Reduced from spacingXLarge
              const _CollapsibleDetailsCard(),
              const SizedBox(height: UIConstants.spacingLarge), // Reduced from spacingXLarge
              _buildHourlyForecastSection(context),
              const SizedBox(height: UIConstants.spacingLarge), // Reduced from spacingXLarge
              _buildPrecipitationChart(context),
              const SizedBox(height: UIConstants.spacingLarge), // Reduced from spacingXLarge
              _buildDailyForecastSection(context),
              const SizedBox(height: UIConstants.spacingLarge), // Reduced from spacingXLarge
              _buildRadarSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the NWS alerts section
  Widget _buildAlertsSection(BuildContext context) {
    return RepaintBoundary(
      child: Selector<WeatherProvider, List<NwsAlertFeature>>(
        selector: (context, provider) => provider.nwsAlerts,
        builder: (context, alerts, child) {
          if (alerts.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(bottom: UIConstants.spacingLarge), // Reduced from spacingXLarge
              child: NwsAlertBanner(alerts: alerts),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Builds the liquid glass test section to compare old vs new implementations




  /// Builds the hourly forecast section with title
  Widget _buildHourlyForecastSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hourly Forecast', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: UIConstants.spacingStandard), // Reduced from spacingLarge
        const _HourlyForecastListSection(),
      ],
    );
  }

  /// Builds the daily forecast section with title
  Widget _buildDailyForecastSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Forecast', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: UIConstants.spacingStandard), // Reduced from spacingLarge
        const _DailyForecastListSection(),
      ],
    );
  }

  /// Builds the radar section with title
  Widget _buildRadarSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Radar', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: UIConstants.spacingStandard), // Reduced from spacingLarge
        _buildRadarCard(context),
      ],
    );
  }

  Widget _buildCurrentConditionsCard(BuildContext context) {
    return Selector<WeatherProvider, WeatherData>(
      selector: (context, provider) => provider.weatherData!,
      builder: (context, weatherData, child) {
        final conditions = weatherData.currentConditions!;
        final currentTime = conditions.timestamp?.toLocal() ?? DateTime.now();
        final sunrise = weatherData.sunrise;
        final sunset = weatherData.sunset;
        
        // Use sunrise/sunset times if available, otherwise fallback to hour-based logic
        final isNight = sunrise != null && sunset != null 
            ? currentTime.isBefore(sunrise) || currentTime.isAfter(sunset)
            : currentTime.hour < 6 || currentTime.hour > 18;
            
        final iconPath = WeatherUtils.getWeatherIconAsset(
          conditions.textDescription,
          isNight: isNight,
        );
        final highLow = WeatherUtils.getTodayHighLow(weatherData.forecast);
        final high = highLow['high'];
        final low = highLow['low'];

        return RepaintBoundary(
          child: GlassCard(
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusStandard),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacingXXXLarge, // 24.0px - more left/right padding
              vertical: UIConstants.spacingLarge,    // 20.0px - keep top/bottom padding
            ), // Increased from spacingXLarge to properly align with other cards
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(builder: (context) => Text('${conditions.temperature!.round()}°', style: Theme.of(context).textTheme.displayLarge)),
                          if (conditions.apparentTemperature != null)
                            Builder(builder: (context) => Text('Feels like ${conditions.apparentTemperature!.round()}°', style: Theme.of(context).textTheme.bodyLarge)),
                          const SizedBox(height: UIConstants.spacingTiny),
                          Builder(builder: (context) => Text(conditions.textDescription ?? 'No description', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20), overflow: TextOverflow.ellipsis, maxLines: 2)),
                          const SizedBox(height: UIConstants.spacingTiny), // Increased from spacingSmall for better balance with larger padding
                          if (high != null && low != null)
                            Builder(builder: (context) => Text('H: $high°  L: $low°', style: Theme.of(context).textTheme.bodyLarge)),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: UIConstants.spacingStandard),
                      child: Image.asset(
                        iconPath,
                        width: kIconSizeLarge,
                        height: kIconSizeLarge,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UIConstants.spacingLarge), // Reduced from spacingXLarge
                Align(
                  alignment: Alignment.centerLeft,
                  child: Builder(builder: (context) => Text('Updated: ${_dateTimeFormatter.format(conditions.timestamp!.toLocal())}', style: Theme.of(context).textTheme.bodySmall)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Legacy _buildHourlyForecastRow removed in favor of _HourlyForecastListSection

  Widget _buildPrecipitationChart(BuildContext context) {
    return Selector<WeatherProvider, List<HourlyForecast>?>(
      selector: (context, provider) => provider.hourlyForecast,
      builder: (context, hourlyForecast, child) {
        if (hourlyForecast == null || hourlyForecast.isEmpty) {
          return const SizedBox.shrink();
        }

        // Only show if any hour in the next 24 has nonzero precipProbability or precipAmount
        final now = DateTime.now();
        final filtered = hourlyForecast
            .where((f) => f.time.toLocal().isAfter(now.subtract(const Duration(minutes: 30))))
            .take(24)
            .toList();
        final hasRain = filtered.any((f) =>
          (f.precipProbability != null && f.precipProbability! > 0) ||
          (f.precipAmount != null && f.precipAmount! > 0)
        );
        if (!hasRain) {
          return GlassCard(
            priority: GlassCardPriority.standard,
            child: Row(
              children: [
                const Icon(Icons.water_drop_outlined, color: Colors.white, size: 22),
                const SizedBox(width: UIConstants.spacingLarge), // Reduced from spacingXLarge
                Expanded(child: Builder(builder: (context) => Text('No precipitation expected in the next 24 hours', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)))),
              ],
            ),
          );
        }

        return Selector<WeatherProvider, WeatherData>(
          selector: (context, provider) => provider.weatherData!,
          builder: (context, weatherData, child) {
            return PrecipitationChart(
              hourlyForecast: hourlyForecast,
            );
          },
        );
      },
    );
  }

  // Legacy _buildForecastSection removed in favor of _DailyForecastListSection

  Widget _buildRadarCard(BuildContext context) {
    return Selector<WeatherProvider, SDCity>(
      selector: (context, provider) => provider.selectedCity,
      builder: (context, city, child) {
        return GlassCard(
          priority: GlassCardPriority.standard,
          child: RadarCard(
            city: city,
            onTap: () {
              final condition = context.read<WeatherProvider>().weatherData?.currentConditions?.textDescription;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RadarPage(
                    weatherCondition: condition,
                    citySelector: citySelector,
                    currentScreenId: 'radar',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _HourlyForecastListSection extends StatefulWidget {
  const _HourlyForecastListSection();

  @override
  State<_HourlyForecastListSection> createState() => _HourlyForecastListSectionState();
}

class _HourlyForecastListSectionState extends State<_HourlyForecastListSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return _buildHourlyForecastList(context);
  }

  Widget _buildHourlyForecastList(BuildContext context) {
    return Selector<WeatherProvider, List<HourlyForecast>?>(
      selector: (context, provider) => provider.hourlyForecast,
      builder: (context, hourlyForecast, child) {
        if (hourlyForecast == null || hourlyForecast.isEmpty) {
          return const SizedBox.shrink();
        }
        final DateTime now = DateTime.now();
        final List<HourlyForecast> sorted = List<HourlyForecast>.from(hourlyForecast)
          ..sort((a, b) => a.time.toLocal().compareTo(b.time.toLocal()));
        final List<HourlyForecast> next24 = sorted
            .where((f) => f.time.toLocal().isAfter(now.subtract(const Duration(minutes: 30))))
            .take(24)
            .toList();

        final List<HourlyForecast> visible = _isExpanded ? next24 : next24.take(6).toList();

        return Selector<WeatherProvider, WeatherData>(
          selector: (context, provider) => provider.weatherData!,
          builder: (context, weatherData, child) {
            Widget listContent;
            
            if (_isExpanded) {
              // Use ListView when expanded
              listContent = ListView.separated(
                physics: const ClampingScrollPhysics(),
                primary: false,
                itemCount: visible.length,
                separatorBuilder: (context, index) => Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                  margin: const EdgeInsets.symmetric(horizontal: UIConstants.spacingLarge), // Reduced from spacingXLarge
                ),
                itemBuilder: (context, index) {
                  final HourlyForecast f = visible[index];
                  return HourlyForecastListItem(
                    forecast: f,
                    sunrise: weatherData.sunrise,
                    sunset: weatherData.sunset,
                    tomorrowSunrise: weatherData.tomorrowSunrise,
                    tomorrowSunset: weatherData.tomorrowSunset,
                  );
                },
              );
            } else {
              // Use Column when collapsed for proper sizing
              listContent = Column(
                children: [
                  for (int i = 0; i < visible.length; i++) ...[
                    if (i > 0)
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.2),
                        margin: const EdgeInsets.symmetric(horizontal: UIConstants.spacingLarge), // Reduced from spacingXLarge
                      ),
                    HourlyForecastListItem(
                      forecast: visible[i],
                      sunrise: weatherData.sunrise,
                      sunset: weatherData.sunset,
                      tomorrowSunrise: weatherData.tomorrowSunrise,
                      tomorrowSunset: weatherData.tomorrowSunset,
                    ),
                  ],
                  // Add caret indicator at the bottom
                  if (next24.length > 6)
                    Padding(
                      padding: const EdgeInsets.only(top: UIConstants.spacingSmall), // Reduced from spacingStandard
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 24,
                      ),
                    ),
                ],
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: GlassCard(
                    priority: GlassCardPriority.standard,
                    child: _isExpanded
                        ? SizedBox(
                            height: 360,
                            child: listContent,
                          )
                        : listContent,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DailyForecastListSection extends StatefulWidget {
  const _DailyForecastListSection();

  @override
  State<_DailyForecastListSection> createState() => _DailyForecastListSectionState();
}

class _DailyForecastListSectionState extends State<_DailyForecastListSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return _buildDailyForecastList(context);
  }

  Widget _buildDailyForecastList(BuildContext context) {
    return Selector<WeatherProvider, List<ForecastPeriod>>(
      selector: (context, provider) => provider.weatherData!.forecast,
      builder: (context, forecast, child) {
        if (forecast.isEmpty) {
          return const SizedBox.shrink();
        }

        final Map<String, List<ForecastPeriod>> forecastByDay = <String, List<ForecastPeriod>>{};
        for (final ForecastPeriod period in forecast) {
          final String dateKey = DateFormat('yyyy-MM-dd').format(period.startTime);
          forecastByDay.putIfAbsent(dateKey, () => <ForecastPeriod>[]).add(period);
        }

        final List<String> sortedKeys = forecastByDay.keys.toList()
          ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

        final List<String> visible = _isExpanded ? sortedKeys : sortedKeys.take(4).toList();

        Widget listContent;
        
        if (_isExpanded) {
          // Use ListView when expanded
          listContent = ListView.separated(
            physics: const ClampingScrollPhysics(),
            primary: false,
            itemCount: visible.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.2),
              margin: const EdgeInsets.symmetric(horizontal: UIConstants.spacingLarge), // Reduced from spacingXLarge
            ),
            itemBuilder: (context, index) {
              final String dateKey = visible[index];
              final List<ForecastPeriod> periods = forecastByDay[dateKey]!;
              final DateTime date = DateTime.parse(dateKey);

              ForecastPeriod? dayPeriod;
              ForecastPeriod? nightPeriod;
              try {
                dayPeriod = periods.firstWhere((p) => p.isDaytime);
              } catch (_) {
                dayPeriod = null;
              }
              try {
                nightPeriod = periods.firstWhere((p) => !p.isDaytime);
              } catch (_) {
                nightPeriod = null;
              }

              return DailyForecastListItem(
                date: date,
                dayPeriod: dayPeriod,
                nightPeriod: nightPeriod,
              );
            },
          );
        } else {
          // Use Column when collapsed for proper sizing
          listContent = Column(
            children: [
              for (int i = 0; i < visible.length; i++) ...[
                if (i > 0)
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.2),
                    margin: const EdgeInsets.symmetric(horizontal: UIConstants.spacingLarge), // Reduced from spacingXLarge
                  ),
                DailyForecastListItem(
                  date: DateTime.parse(visible[i]),
                  dayPeriod: forecastByDay[visible[i]]!.firstWhere((p) => p.isDaytime, orElse: () => forecastByDay[visible[i]]!.first),
                  nightPeriod: forecastByDay[visible[i]]!.firstWhere((p) => !p.isDaytime, orElse: () => forecastByDay[visible[i]]!.first),
                ),
              ],
              // Add caret indicator at the bottom
              if (sortedKeys.length > 4)
                Padding(
                  padding: const EdgeInsets.only(top: UIConstants.spacingSmall), // Reduced from spacingStandard
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 24,
                  ),
                ),
            ],
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: GlassCard(
                priority: GlassCardPriority.standard,
                child: _isExpanded
                    ? SizedBox(
                        height: 400,
                        child: listContent,
                    )
                    : listContent,
              ),
            ),
          ),
        );
      },
    );
  }
}
