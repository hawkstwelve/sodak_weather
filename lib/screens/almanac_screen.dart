import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/almanac_data.dart';
import '../models/sd_city.dart';
import '../services/almanac_service.dart';
import '../providers/weather_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/app_drawer.dart';

class AlmanacScreen extends StatefulWidget {
  final Widget? citySelector;
  final Function(int)? onNavigate;
  final String currentScreenId;

  const AlmanacScreen({
    super.key,
    this.citySelector,
    this.onNavigate,
    required this.currentScreenId,
  });

  @override
  State<AlmanacScreen> createState() => _AlmanacScreenState();
}

class _AlmanacScreenState extends State<AlmanacScreen> {
  Future<AlmanacData>? _almanacDataFuture;
  final bool _isMetric = false;
  String? _errorMessage;
  SDCity? _lastFetchedCity;
  bool? _lastIsUsingLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAlmanacData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final currentCity = weatherProvider.selectedCity;
    final isUsingLocation = weatherProvider.isUsingLocation;

    // Fetch if city changed, or if GPS use status changed.
    final locationData = isUsingLocation ? locationProvider.currentLocation : currentCity;
    final lastLocationData = (_lastIsUsingLocation ?? false) ? _lastFetchedCity : _lastFetchedCity;

    if (locationData != lastLocationData) {
      _lastFetchedCity = currentCity;
      _lastIsUsingLocation = isUsingLocation;
      _fetchAlmanacData();
    }
  }

  Future<void> _fetchAlmanacData() async {
    if (!mounted) return;
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    // Show loading indicator
    setState(() {
      _almanacDataFuture = null;
      _errorMessage = null;
    });

    double latitude;
    double longitude;

    if (weatherProvider.isUsingLocation && locationProvider.currentLocation != null) {
      latitude = locationProvider.currentLocation!.latitude;
      longitude = locationProvider.currentLocation!.longitude;
    } else {
      latitude = weatherProvider.selectedCity.latitude;
      longitude = weatherProvider.selectedCity.longitude;
    }

    try {
      final future = AlmanacService.fetchHistoricalData(
        latitude: latitude,
        longitude: longitude,
        targetDate: DateTime.now(),
        isMetric: _isMetric,
      );
      if (mounted) {
        setState(() {
          _almanacDataFuture = future;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _almanacDataFuture = Future.error(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final condition = weatherProvider.weatherData?.currentConditions?.textDescription;
    final gradient = AppTheme.getGradientForCondition(condition);
    final todayFormatted = DateFormat("MMMM d").format(DateTime.now());
    final precipUnit = _isMetric ? "mm" : "in";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Historical Almanac'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: widget.citySelector,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Content
              Expanded(
                child: FutureBuilder<AlmanacData>(
                  future: _almanacDataFuture,
                  builder: (context, snapshot) {
                    if (_almanacDataFuture == null || snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.loadingIndicatorColor),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppTheme.textLight,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Unable to load historical data',
                                  style: AppTheme.headingSmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  // Display the specific error message
                                  snapshot.error.toString().replaceFirst("Exception: ", ""),
                                  style: AppTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchAlmanacData,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData) {
                      return Center(
                        child: Text(
                          'No historical data available.',
                          style: AppTheme.bodyLarge,
                        ),
                      );
                    }

                    final data = snapshot.data!;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            'Almanac for $todayFormatted',
                            style: AppTheme.headingLarge,
                          ),
                          const SizedBox(height: 24),

                          // Records Card
                          GlassCard(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'All-Time Records',
                                    style: AppTheme.headingSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildRecordRow(
                                    'Record High',
                                    '${data.recordHighTemp.toStringAsFixed(1)}°',
                                    data.recordHighYear.toString(),
                                    Colors.red.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildRecordRow(
                                    'Record Low',
                                    '${data.recordLowTemp.toStringAsFixed(1)}°',
                                    data.recordLowYear.toString(),
                                    Colors.blue.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildRecordRow(
                                    'Record Precipitation',
                                    '${data.recordPrecip.toStringAsFixed(2)} $precipUnit',
                                    data.recordPrecipYear.toString(),
                                    Colors.green.shade300,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Averages Card
                          GlassCard(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Historical Averages',
                                    style: AppTheme.headingSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildAverageRow(
                                    'Average High',
                                    '${data.averageHigh.toStringAsFixed(1)}°',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildAverageRow(
                                    'Average Low',
                                    '${data.averageLow.toStringAsFixed(1)}°',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildAverageRow(
                                    'Average Precipitation',
                                    '${data.averagePrecipitation.toStringAsFixed(2)} $precipUnit',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Recent Years Card
                          if (data.recentYears.isNotEmpty)
                            GlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "This Day Through the Years",
                                      style: AppTheme.headingSmall,
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 220,
                                      child: _buildRecentYearsChart(data.recentYears),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: AppDrawer(
        gradientColors: gradient,
        selectedCity: weatherProvider.selectedCity,
        currentScreenId: widget.currentScreenId,
        onNavigationTap: (index) => widget.onNavigate?.call(index),
      ),
    );
  }

  Widget _buildRecordRow(String label, String value, String year, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyLarge),
        Row(
          children: [
            Text(
              value,
              style: AppTheme.bodyLarge.copyWith(
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '($year)',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAverageRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyLarge),
        Text(
          value,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentYearsChart(List<YearlyData> recentYears) {
    final sortedYears = List<YearlyData>.from(recentYears)..sort((a, b) => a.year.compareTo(b.year));

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: NumericAxis(
        numberFormat: NumberFormat("####"),
        interval: 1,
        majorGridLines: MajorGridLines(width: 0.5, color: Colors.white.withOpacity(0.2)),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: AppTheme.bodySmall,
      ),
      primaryYAxis: NumericAxis(
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: AppTheme.bodySmall,
      ),
      series: <CartesianSeries<YearlyData, int>>[
        SplineSeries<YearlyData, int>(
          dataSource: sortedYears,
          xValueMapper: (YearlyData data, _) => data.year,
          yValueMapper: (YearlyData data, _) => data.highTemp.isNaN ? null : data.highTemp,
          name: 'High',
          color: Colors.red.shade300,
          width: 3,
          markerSettings: const MarkerSettings(isVisible: true, color: Colors.white, height: 4, width: 4),
        ),
        SplineSeries<YearlyData, int>(
          dataSource: sortedYears,
          xValueMapper: (YearlyData data, _) => data.year,
          yValueMapper: (YearlyData data, _) => data.lowTemp.isNaN ? null : data.lowTemp,
          name: 'Low',
          color: Colors.blue.shade300,
          width: 3,
          markerSettings: const MarkerSettings(isVisible: true, color: Colors.white, height: 4, width: 4),
        ),
        SplineSeries<YearlyData, int>(
          dataSource: sortedYears,
          xValueMapper: (YearlyData data, _) => data.year,
          yValueMapper: (YearlyData data, _) => data.precip.isNaN ? null : data.precip,
          name: 'Precip',
          color: Colors.green.shade300,
          width: 3,
          markerSettings: const MarkerSettings(isVisible: true, color: Colors.white, height: 4, width: 4),
        )
      ],
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: AppTheme.bodySmall,
        iconHeight: 10,
        iconWidth: 10,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineType: TrackballLineType.vertical,
        tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
        tooltipSettings: InteractiveTooltip(
          enable: true,
          color: AppTheme.glassCardColor,
          textStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textLight),
          format: 'point.x\nseries.name: point.y',
        ),
      ),
    );
  }
} 