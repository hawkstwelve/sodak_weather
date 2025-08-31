import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/hourly_forecast.dart';
// import '../theme/app_theme.dart';
import 'glass/glass_card.dart';
import '../constants/ui_constants.dart';

class PrecipitationChart extends StatefulWidget {
  final List<HourlyForecast> hourlyForecast;

  const PrecipitationChart({
    super.key,
    required this.hourlyForecast,
  });

  @override
  State<PrecipitationChart> createState() => _PrecipitationChartState();
}

class _PrecipitationChartState extends State<PrecipitationChart> {
  late List<_ChartData> _chartData;
  late TrackballBehavior _trackballBehavior;
  late double _maxAmount;

  @override
  void initState() {
    super.initState();
    _prepareChartData();
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.longPress,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      tooltipSettings: const InteractiveTooltip(
        format: 'point.y',
        borderColor: Colors.white,
        borderWidth: 1,
        color: Color(0x80FFFFFF),
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        canShowMarker: true,
      ),
    );
  }

  void _prepareChartData() {
    final now = DateTime.now();
    final filteredForecast = widget.hourlyForecast
        .where((forecast) =>
            forecast.time.toLocal().isAfter(now.subtract(const Duration(minutes: 30))))
        .take(24)
        .toList()
      ..sort((a, b) => a.time.toLocal().compareTo(b.time.toLocal()));

    _chartData = filteredForecast.map((forecast) {
      double amount = 0.0;
      if (forecast.precipAmount != null) {
        amount = forecast.precipAmount!;
        if (forecast.precipUnit == 'MM') {
          amount /= 25.4;
        }
      }
      return _ChartData(
        forecast.time.toLocal(),
        (forecast.precipProbability ?? 0).toDouble(),
        amount,
      );
    }).toList();

    final maxVal = _chartData.map((d) => d.amount ?? 0).reduce((a, b) => a > b ? a : b);
    if (maxVal < 0.1) {
      _maxAmount = 0.5;
    } else {
      _maxAmount = (maxVal * 10).ceil() / 10.0 + 0.1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chartData.isEmpty) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: GlassCard(
        priority: GlassCardPriority.standard,
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingSmall), // Reduced from spacingStandard
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Builder(builder: (context) => Icon(Icons.water_drop, color: Theme.of(context).colorScheme.onSurface, size: 20)),
                  const SizedBox(width: UIConstants.spacingStandard), // Reduced from spacingStandard
                  Text(
                    '24-Hour Precipitation',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.spacingStandard), // Reduced from spacingLarge
              SizedBox(
                height: UIConstants.chartHeight,
                child: SfCartesianChart(
                  plotAreaBorderColor: Colors.white,
                  plotAreaBorderWidth: 1,
                  backgroundColor: Colors.transparent,
                  primaryXAxis: DateTimeAxis(
                    majorGridLines: const MajorGridLines(width: 0),
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(size: 0),
                    labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                    intervalType: DateTimeIntervalType.hours,
                    dateFormat: DateFormat('ha'),
                    edgeLabelPlacement: EdgeLabelPlacement.shift,
                  ),
                  primaryYAxis: NumericAxis(
                    name: 'probability',
                    minimum: 0,
                    maximum: 100,
                    interval: 25,
                    axisLine: const AxisLine(width: 1, color: Colors.white),
                    majorTickLines: const MajorTickLines(
                      size: 0,
                      color: Colors.white,
                    ),
                    majorGridLines: const MajorGridLines(
                      width: 1,
                      color: Color(0x40FFFFFF),
                    ),
                    minorTickLines: const MinorTickLines(size: 0),
                    minorGridLines: const MinorGridLines(width: 0),
                    labelFormat: '{value}%',
                    labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  axes: <ChartAxis>[
                    NumericAxis(
                      name: 'amount',
                      opposedPosition: true,
                      minimum: 0,
                      maximum: _maxAmount,
                      interval: _maxAmount / 4,
                      axisLine: const AxisLine(width: 1, color: Colors.white),
                      majorTickLines: const MajorTickLines(
                        size: 0,
                        color: Colors.white,
                      ),
                      majorGridLines: const MajorGridLines(
                        width: 1,
                        color: Color(0x40FFFFFF),
                      ),
                      minorTickLines: const MinorTickLines(size: 0),
                      minorGridLines: const MinorGridLines(width: 0),
                      labelFormat: '{value} in',
                      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                  series: _getSeries(),
                  trackballBehavior: _trackballBehavior,
                  enableAxisAnimation: true,
                  zoomPanBehavior: ZoomPanBehavior(
                    enablePinching: true,
                    enablePanning: true,
                    enableDoubleTapZooming: true,
                  ),
                ),
              ),
              const SizedBox(height: UIConstants.spacingStandard),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem('Probability', Colors.blue),
                  _buildLegendItem('Amount', Colors.amber),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<CartesianSeries<_ChartData, DateTime>> _getSeries() {
    return <CartesianSeries<_ChartData, DateTime>>[
      SplineAreaSeries<_ChartData, DateTime>(
        dataSource: _chartData,
        xValueMapper: (_ChartData data, _) => data.time,
        yValueMapper: (_ChartData data, _) => data.probability,
        yAxisName: 'probability',
        name: 'Probability',
        color: Colors.blue.withAlpha((0.3 * 255).round()),
        borderColor: Colors.blue,
        borderWidth: 2,
        animationDuration: 1000,
        selectionBehavior: SelectionBehavior(
          enable: true,
          selectedColor: Colors.blue.withAlpha((0.5 * 255).round()),
        ),
      ),
      SplineAreaSeries<_ChartData, DateTime>(
        dataSource: _chartData,
        xValueMapper: (_ChartData data, _) => data.time,
        yValueMapper: (_ChartData data, _) => data.amount,
        yAxisName: 'amount',
        name: 'Amount',
        color: Colors.amber.withAlpha((0.3 * 255).round()),
        borderColor: Colors.amber,
        borderWidth: 2,
        animationDuration: 1000,
        selectionBehavior: SelectionBehavior(
          enable: true,
          selectedColor: Colors.amber.withAlpha((0.5 * 255).round()),
        ),
      ),
    ];
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: UIConstants.spacingLarge,
          height: UIConstants.spacingLarge,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(UIConstants.spacingTiny),
          ),
        ),
        const SizedBox(width: UIConstants.spacingSmall),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

class _ChartData {
  _ChartData(this.time, this.probability, this.amount);
  final DateTime time;
  final double? probability;
  final double? amount;
} 