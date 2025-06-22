import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/hourly_forecast.dart';
import '../theme/app_theme.dart';
import 'glass/glass_card.dart';

class PrecipitationChart extends StatefulWidget {
  final List<HourlyForecast> hourlyForecast;
  final bool useBlur;

  const PrecipitationChart({
    super.key,
    required this.hourlyForecast,
    this.useBlur = false,
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

    return GlassCard(
      useBlur: widget.useBlur,
      opacity: 0.2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop, color: AppTheme.textLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  '24-Hour Precipitation',
                  style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                plotAreaBorderColor: Colors.white,
                plotAreaBorderWidth: 1,
                backgroundColor: Colors.transparent,
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                  labelStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textMedium),
                ),
                primaryYAxis: NumericAxis(
                  name: 'probability',
                  minimum: 0,
                  maximum: 100,
                  interval: 25,
                  axisLine: const AxisLine(width: 1, color: Colors.white),
                  majorTickLines: const MajorTickLines(
                    size: 5,
                    color: Colors.white,
                  ),
                  majorGridLines: const MajorGridLines(
                    width: 1,
                    color: Color(0x40FFFFFF),
                  ),
                  minorTickLines: const MinorTickLines(size: 0),
                  minorGridLines: const MinorGridLines(width: 0),
                  labelFormat: '{value}%',
                  labelStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textMedium),
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
                      size: 5,
                      color: Colors.white,
                    ),
                    majorGridLines: const MajorGridLines(
                      width: 1,
                      color: Color(0x40FFFFFF),
                    ),
                    minorTickLines: const MinorTickLines(size: 0),
                    minorGridLines: const MinorGridLines(width: 0),
                    labelFormat: '{value} in',
                    labelStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textMedium),
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
            const SizedBox(height: 12),
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
    );
  }

  List<CartesianSeries<_ChartData, String>> _getSeries() {
    return <CartesianSeries<_ChartData, String>>[
      SplineAreaSeries<_ChartData, String>(
        dataSource: _chartData,
        xValueMapper: (_ChartData data, _) => DateFormat('ha').format(data.time),
        yValueMapper: (_ChartData data, _) => data.probability,
        yAxisName: 'probability',
        name: 'Probability',
        color: Colors.blue.withOpacity(0.3),
        borderColor: Colors.blue,
        borderWidth: 2,
        animationDuration: 1000,
        selectionBehavior: SelectionBehavior(
          enable: true,
          selectedColor: Colors.blue.withOpacity(0.5),
        ),
      ),
      SplineAreaSeries<_ChartData, String>(
        dataSource: _chartData,
        xValueMapper: (_ChartData data, _) => DateFormat('ha').format(data.time),
        yValueMapper: (_ChartData data, _) => data.amount,
        yAxisName: 'amount',
        name: 'Amount',
        color: Colors.amber.withOpacity(0.3),
        borderColor: Colors.amber,
        borderWidth: 2,
        animationDuration: 1000,
        selectionBehavior: SelectionBehavior(
          enable: true,
          selectedColor: Colors.amber.withOpacity(0.5),
        ),
      ),
    ];
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textMedium),
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