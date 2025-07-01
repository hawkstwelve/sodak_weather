import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weather_icons/weather_icons.dart';
import '../models/weather_data.dart';
import '../models/hourly_forecast.dart';
import '../models/sd_city.dart';
import '../models/nws_alert_model.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/forecast_card.dart';
import '../widgets/hourly_forecast_card.dart';
import '../widgets/precipitation_chart.dart';
import '../utils/weather_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/nws_alert_banner.dart';
import '../screens/radar_screen.dart';
import '../widgets/radar_card.dart';
import '../providers/weather_provider.dart';
import '../constants/ui_constants.dart';

// Constants for styling and layout
const double kIconSizeLarge = UIConstants.iconSizeLarge * 2.5;
const double kIconSizeMedium = UIConstants.iconSizeLarge;
const double kIconSizeSmall = UIConstants.iconSizeMedium * 1.75;
const double kCardPadding = UIConstants.spacingXXXLarge;
const double kSpacingStandard = UIConstants.spacingXLarge;
const double kSpacingSmall = UIConstants.spacingStandard;
const double kForecastCardWidth = 110.0;
const double kForecastCardHeight = UIConstants.cardHeightMedium;
const double kHourlyForecastCardHeight = UIConstants.cardHeightLarge - 10;

class _CollapsibleDetailsCard extends StatefulWidget {
  const _CollapsibleDetailsCard({Key? key}) : super(key: key);

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
          useBlur: false,
          opacity: UIConstants.opacityLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: UIConstants.spacingLarge, horizontal: UIConstants.spacingXXLarge),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Conditions',
                  style: AppTheme.bodyLarge,
                ),
                const Icon(Icons.expand_more, color: Colors.white),
              ],
            ),
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
                const BoxedIcon(WeatherIcons.humidity, color: AppTheme.textLight, size: 28),
                'Humidity',
                '${conditions.humidity ?? 'N/A'}%',
              ),
              _buildDetailItem(
                const BoxedIcon(WeatherIcons.thermometer, color: AppTheme.textLight, size: 28),
                'Dewpoint',
                conditions.dewpoint != null
                    ? '${conditions.dewpoint!.round()}°'
                    : 'N/A',
              ),
              _buildDetailItem(
                const BoxedIcon(WeatherIcons.rain, color: AppTheme.textLight, size: 28),
                'Rain (24h)',
                (additionalData['rain24hInches'] != null
                    ? '${additionalData['rain24hInches'].toStringAsFixed(2)} in'
                    : '0 in'),
              ),
              _buildDetailItem(
                const BoxedIcon(WeatherIcons.strong_wind, color: AppTheme.textLight, size: 28),
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
                const BoxedIcon(WeatherIcons.hot, color: AppTheme.textLight, size: 28),
                'UV',
                WeatherUtils.uvIndexDescription(conditions.uvIndex),
              ),
              _buildDetailItem(
                const BoxedIcon(WeatherIcons.dust, color: AppTheme.textLight, size: 28),
                'AQI',
                _shortAqiCategory(additionalData['aqiCategory']) ?? 'N/A',
              ),
              _buildDetailItem(
                const BoxedIcon(WeatherIcons.sunrise, color: AppTheme.textLight, size: 28),
                'Sunrise',
                sunrise != null ? WeatherPage._timeFormatter.format(sunrise) : 'N/A',
              ),
              _buildDetailItem(
                const BoxedIcon(WeatherIcons.sunset, color: AppTheme.textLight, size: 28),
                'Sunset',
                sunset != null ? WeatherPage._timeFormatter.format(sunset) : 'N/A',
              ),
            ],
          ];
          return GlassCard(
            useBlur: false,
            opacity: UIConstants.opacityLow,
            child: Padding(
              padding: const EdgeInsets.all(UIConstants.spacingXLarge),
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
                              margin: const EdgeInsets.symmetric(vertical: UIConstants.spacingStandard),
                            ),
                        ],
                      ],
                    ),
                    if (row == 0)
                      Container(
                        height: UIConstants.dividerHeight,
                        color: const Color.fromRGBO(255, 255, 255, 0.12),
                        margin: const EdgeInsets.symmetric(vertical: UIConstants.spacingStandard),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildDetailItem(Widget icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacingTiny, vertical: UIConstants.spacingTiny),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(height: UIConstants.spacingMedium),
        Text(label, style: AppTheme.bodyBold),
        const SizedBox(height: UIConstants.spacingTiny),
        Text(
          value,
          style: AppTheme.bodySmall,
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
                child: _buildContent(context),
              ),
            );
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

  /// Builds the loading indicator widget
  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator(color: AppTheme.loadingIndicatorColor));
  }

  /// Builds the error widget with retry functionality
  Widget _buildErrorWidget(BuildContext context, String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: UIConstants.iconSizeLarge, color: Colors.red),
          const SizedBox(height: UIConstants.spacingXLarge),
          Text('Error: $errorMessage', textAlign: TextAlign.center, style: AppTheme.headingMedium),
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
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingXLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAlertsSection(context),
              _buildCurrentConditionsCard(context),
              const SizedBox(height: UIConstants.spacingXXXLarge),
              const _CollapsibleDetailsCard(),
              const SizedBox(height: UIConstants.spacingXXXLarge),
              _buildHourlyForecastSection(context),
              const SizedBox(height: UIConstants.spacingXXXLarge),
              _buildPrecipitationChart(context),
              const SizedBox(height: UIConstants.spacingXXXLarge),
              _buildDailyForecastSection(context),
              const SizedBox(height: UIConstants.spacingHuge),
              _buildRadarSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the NWS alerts section
  Widget _buildAlertsSection(BuildContext context) {
    return Selector<WeatherProvider, List<NwsAlertFeature>>(
      selector: (context, provider) => provider.nwsAlerts,
      builder: (context, alerts, child) {
        if (alerts.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: UIConstants.spacingXLarge),
            child: NwsAlertBanner(alerts: alerts),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Builds the hourly forecast section with title
  Widget _buildHourlyForecastSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hourly Forecast', style: AppTheme.headingSmall),
        const SizedBox(height: UIConstants.spacingXLarge),
        _buildHourlyForecastRow(context),
      ],
    );
  }

  /// Builds the daily forecast section with title
  Widget _buildDailyForecastSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Forecast', style: AppTheme.headingSmall),
        const SizedBox(height: UIConstants.spacingXLarge),
        _buildForecastSection(context),
      ],
    );
  }

  /// Builds the radar section with title
  Widget _buildRadarSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Radar', style: AppTheme.headingSmall),
        const SizedBox(height: UIConstants.spacingXLarge),
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

        return GlassCard(
          useBlur: false,
          opacity: 0.4,
          child: Padding(
            padding: const EdgeInsets.all(UIConstants.spacingXLarge),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${conditions.temperature!.round()}°',
                            style: AppTheme.temperature,
                          ),
                          if (conditions.apparentTemperature != null)
                            Text(
                              'Feels like ${conditions.apparentTemperature!.round()}°',
                              style: AppTheme.bodyLarge,
                            ),
                          const SizedBox(height: UIConstants.spacingTiny),
                          Text(
                            conditions.textDescription ?? 'No description',
                            style: AppTheme.headingSmall.copyWith(fontSize: 20),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: UIConstants.spacingTiny),
                          if (high != null && low != null)
                            Text(
                              'H: $high°  L: $low°',
                              style: AppTheme.bodyLarge,
                            ),
                        ],
                      ),
                    ),
                    Image.asset(
                      iconPath,
                      width: kIconSizeLarge,
                      height: kIconSizeLarge,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: UIConstants.spacingXLarge),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Updated: ${_dateTimeFormatter.format(conditions.timestamp!.toLocal())}',
                    style: AppTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHourlyForecastRow(BuildContext context) {
    return Selector<WeatherProvider, List<HourlyForecast>?>(
      selector: (context, provider) => provider.hourlyForecast,
      builder: (context, hourlyForecast, child) {
        if (hourlyForecast == null || hourlyForecast.isEmpty) {
          return const SizedBox.shrink();
        }
        final now = DateTime.now();
        final List<HourlyForecast> sorted = List.from(hourlyForecast);
        sorted.sort((a, b) => a.time.toLocal().compareTo(b.time.toLocal()));
        int startIdx = sorted.indexWhere(
          (f) => f.time.toLocal().isAfter(now.subtract(const Duration(minutes: 30))),
        );
        if (startIdx == -1) startIdx = 0;

        return Selector<WeatherProvider, WeatherData>(
          selector: (context, provider) => provider.weatherData!,
          builder: (context, weatherData, child) {
            return SizedBox(
              height: kHourlyForecastCardHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sorted.length - startIdx,
                itemBuilder: (context, index) {
                  final itemIndex = startIdx + index;
                  return Padding(
                    padding: const EdgeInsets.only(right: UIConstants.spacingXLarge),
                    child: HourlyForecastCard(
                      forecast: sorted[itemIndex],
                      sunrise: weatherData.sunrise,
                      sunset: weatherData.sunset,
                      tomorrowSunrise: weatherData.tomorrowSunrise,
                      tomorrowSunset: weatherData.tomorrowSunset,
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

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
            useBlur: false,
            opacity: 0.2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: UIConstants.spacingXLarge, horizontal: UIConstants.spacingXXLarge),
              child: Row(
                children: [
                  const Icon(Icons.water_drop_outlined, color: Colors.white, size: 22),
                  const SizedBox(width: UIConstants.spacingXLarge),
                  Expanded(
                    child: Text(
                      'No precipitation expected in the next 24 hours',
                      style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Selector<WeatherProvider, WeatherData>(
          selector: (context, provider) => provider.weatherData!,
          builder: (context, weatherData, child) {
            return PrecipitationChart(
              hourlyForecast: hourlyForecast,
              useBlur: false,
            );
          },
        );
      },
    );
  }

  Widget _buildForecastSection(BuildContext context) {
    return Selector<WeatherProvider, List<ForecastPeriod>>(
      selector: (context, provider) => provider.weatherData!.forecast,
      builder: (context, forecast, child) {
        if (forecast.isEmpty) {
          return const SizedBox.shrink();
        }

        final Map<String, List<ForecastPeriod>> forecastByDay = {};
        for (var period in forecast) {
          final dateKey = DateFormat('yyyy-MM-dd').format(period.startTime);
          if (!forecastByDay.containsKey(dateKey)) {
            forecastByDay[dateKey] = [];
          }
          forecastByDay[dateKey]!.add(period);
        }

        return SizedBox(
          height: UIConstants.cardHeightLarge,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: forecastByDay.length,
            separatorBuilder: (context, index) => const SizedBox(width: UIConstants.spacingXLarge),
            itemBuilder: (context, index) {
              final dateKey = forecastByDay.keys.elementAt(index);
              final periods = forecastByDay[dateKey]!;
              final date = DateTime.parse(dateKey);

              final dayPeriod = periods.firstWhere(
                (p) => p.isDaytime,
                orElse: () => periods.first, // Fallback
              );
              final nightPeriod = periods.firstWhere(
                (p) => !p.isDaytime,
                orElse: () => periods.last, // Fallback
              );
              final iconAsset = WeatherUtils.getWeatherIconAsset(
                dayPeriod.shortForecast,
                isNight: false,
              );

              return ForecastCard(
                date: date,
                dayPeriod: dayPeriod,
                nightPeriod: nightPeriod,
                iconAsset: iconAsset,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRadarCard(BuildContext context) {
    return Selector<WeatherProvider, SDCity>(
      selector: (context, provider) => provider.selectedCity,
      builder: (context, city, child) {
        return GlassCard(
          useBlur: false,
          opacity: 0.2,
          child: Padding(
            padding: const EdgeInsets.all(UIConstants.spacingXLarge),
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
          ),
        );
      },
    );
  }
}
