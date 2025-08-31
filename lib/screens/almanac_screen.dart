import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/almanac_data.dart';
import '../models/sd_city.dart';
import '../services/almanac_service.dart';
import '../providers/weather_provider.dart';
import '../providers/location_provider.dart';
// import '../theme/app_theme.dart';
import '../widgets/glass/glass_card.dart';
import '../constants/ui_constants.dart';

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
          _almanacDataFuture = Future.error(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<AlmanacData?>(
        future: _almanacDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Builder(builder: (context) => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(UIConstants.spacingXLarge),
                child: Builder(builder: (context) => Text('Error loading almanac data: ${snapshot.error}', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center)),
              ),
            );
          }
          final AlmanacData? data = snapshot.data;
          if (data == null) {
            return Center(child: Builder(builder: (context) => Text('No almanac data available.', style: Theme.of(context).textTheme.bodyMedium)));
          }
          return RefreshIndicator(
            onRefresh: _fetchAlmanacData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(UIConstants.spacingXLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: UIConstants.spacingXLarge),
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(UIConstants.spacingXXXLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(builder: (context) => Text("Today's Records", style: Theme.of(context).textTheme.headlineSmall)),
                          const SizedBox(height: UIConstants.spacingXLarge),
                          _buildRecordRow('Record High', '${data.recordHighTemp.round()}°', data.recordHighYear, Icons.trending_up),
                          _buildRecordRow('Record Low', '${data.recordLowTemp.round()}°', data.recordLowYear, Icons.trending_down),
                          _buildRecordRow('Record Precip', '${data.recordPrecip.toStringAsFixed(2)}"', data.recordPrecipYear, Icons.water_drop, isPrecip: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingXXXLarge),
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(UIConstants.spacingXXXLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(builder: (context) => Text("Today's Averages", style: Theme.of(context).textTheme.headlineSmall)),
                          const SizedBox(height: UIConstants.spacingXLarge),
                          _buildAverageRow('Average High', '${data.averageHigh.round()}°', Icons.trending_up),
                          _buildAverageRow('Average Low', '${data.averageLow.round()}°', Icons.trending_down),
                          _buildAverageRow('Average Precip', '${data.averagePrecipitation.toStringAsFixed(2)}"', Icons.water_drop, isPrecip: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingXLarge),
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(UIConstants.spacingXXXLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(builder: (context) => Text('This Day Through the Years', style: Theme.of(context).textTheme.headlineSmall)),
                          const SizedBox(height: UIConstants.spacingXLarge),
                          SizedBox(
                            height: UIConstants.cardHeightXXLarge,
                            child: _buildChart(context, data),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordRow(String label, String value, int year, IconData icon, {bool isPrecip = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(builder: (context) => Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          Row(
            children: [
              Icon(
                icon,
                color: isPrecip ? Colors.green.shade400 : (icon == Icons.trending_up ? Colors.red.shade300 : Colors.blue.shade300),
                size: 18,
              ),
              const SizedBox(width: 8),
              Builder(builder: (context) => Text(value, style: Theme.of(context).textTheme.bodyLarge)),
              const SizedBox(width: 4),
              Builder(builder: (context) => Text('($year)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAverageRow(String label, String value, IconData icon, {bool isPrecip = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(builder: (context) => Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          Row(
            children: [
              Icon(
                icon,
                color: isPrecip ? Colors.green.shade200 : (icon == Icons.trending_up ? Colors.red.shade200 : Colors.blue.shade200),
                size: 18,
              ),
              const SizedBox(width: 8),
              Builder(builder: (context) => Text(value, style: Theme.of(context).textTheme.bodyLarge)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, AlmanacData data) {
    final sortedYears = List<YearlyData>.from(data.recentYears)..sort((a, b) => a.year.compareTo(b.year));

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: _buildPrimaryXAxis(),
      primaryYAxis: _buildPrimaryYAxis(),
      axes: <ChartAxis>[_buildPrecipAxis()],
      series: _buildChartSeries(sortedYears),
      legend: _buildChartLegend(),
      trackballBehavior: _buildTrackballBehavior(),
    );
  }

  /// Builds the primary X-axis for the chart
  NumericAxis _buildPrimaryXAxis() {
    return NumericAxis(
      numberFormat: NumberFormat("####"),
      interval: 2,
      majorGridLines: MajorGridLines(width: 0.5, color: Colors.white.withAlpha((0.2 * 255).round())),
      axisLine: const AxisLine(width: 0),
      majorTickLines: const MajorTickLines(size: 0),
      labelStyle: Theme.of(context).textTheme.bodySmall,
    );
  }

  /// Builds the primary Y-axis for temperature
  NumericAxis _buildPrimaryYAxis() {
    return NumericAxis(
      majorGridLines: const MajorGridLines(width: 0),
      axisLine: const AxisLine(width: 0),
      majorTickLines: const MajorTickLines(size: 0),
      labelStyle: Theme.of(context).textTheme.bodySmall,
      title: AxisTitle(text: 'Temperature (°F)', textStyle: Theme.of(context).textTheme.bodySmall),
    );
  }

  /// Builds the precipitation Y-axis
  NumericAxis _buildPrecipAxis() {
    return NumericAxis(
      name: 'precip',
      opposedPosition: true,
      minimum: 0.0,
      maximum: 1.5,
      interval: 0.25,
      axisLine: const AxisLine(width: 0),
      majorTickLines: const MajorTickLines(size: 0),
      majorGridLines: const MajorGridLines(width: 0),
      labelStyle: Theme.of(context).textTheme.bodySmall,
      title: AxisTitle(text: 'Precip (in)', textStyle: Theme.of(context).textTheme.bodySmall),
    );
  }

  /// Builds all chart series (high temp, low temp, precipitation)
  List<CartesianSeries<YearlyData, int>> _buildChartSeries(List<YearlyData> sortedYears) {
    return <CartesianSeries<YearlyData, int>>[
      _buildHighTempSeries(sortedYears),
      _buildLowTempSeries(sortedYears),
      _buildPrecipSeries(sortedYears),
    ];
  }

  /// Builds the high temperature series
  LineSeries<YearlyData, int> _buildHighTempSeries(List<YearlyData> sortedYears) {
    return LineSeries<YearlyData, int>(
      dataSource: sortedYears,
      xValueMapper: (YearlyData data, _) => data.year,
      yValueMapper: (YearlyData data, _) => data.highTemp.isNaN ? null : data.highTemp,
      name: 'High',
      color: Colors.red.shade300,
      width: 3,
      markerSettings: const MarkerSettings(isVisible: true, color: Colors.white, height: 4, width: 4),
    );
  }

  /// Builds the low temperature series
  LineSeries<YearlyData, int> _buildLowTempSeries(List<YearlyData> sortedYears) {
    return LineSeries<YearlyData, int>(
      dataSource: sortedYears,
      xValueMapper: (YearlyData data, _) => data.year,
      yValueMapper: (YearlyData data, _) => data.lowTemp.isNaN ? null : data.lowTemp,
      name: 'Low',
      color: Colors.blue.shade300,
      width: 3,
      markerSettings: const MarkerSettings(isVisible: true, color: Colors.white, height: 4, width: 4),
    );
  }

  /// Builds the precipitation series
  LineSeries<YearlyData, int> _buildPrecipSeries(List<YearlyData> sortedYears) {
    return LineSeries<YearlyData, int>(
      dataSource: sortedYears,
      xValueMapper: (YearlyData data, _) => data.year,
      yValueMapper: (YearlyData data, _) => data.precip.isNaN ? null : data.precip,
      name: 'Precip',
      color: Colors.green.shade300,
      width: 3,
      markerSettings: const MarkerSettings(isVisible: true, color: Colors.white, height: 4, width: 4),
      yAxisName: 'precip',
    );
  }

  /// Builds the chart legend
  Legend _buildChartLegend() {
    return Legend(
      isVisible: true,
      position: LegendPosition.bottom,
      textStyle: Theme.of(context).textTheme.bodySmall,
      iconHeight: 10,
      iconWidth: 10,
      overflowMode: LegendItemOverflowMode.wrap,
    );
  }

  /// Builds the trackball behavior for chart interaction
  TrackballBehavior _buildTrackballBehavior() {
    return TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      lineType: TrackballLineType.vertical,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      tooltipSettings: InteractiveTooltip(
        enable: true,
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        format: 'point.x\nseries.name: point.y',
      ),
    );
  }
} 