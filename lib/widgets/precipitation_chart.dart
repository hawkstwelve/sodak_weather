import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/hourly_forecast.dart';
import '../theme/app_theme.dart';
import 'glass/glass_card.dart';

class PrecipitationChart extends StatelessWidget {
  final List<HourlyForecast> hourlyForecast;
  final DateTime? sunrise;
  final DateTime? sunset;
  final bool useBlur;

  const PrecipitationChart({
    super.key,
    required this.hourlyForecast,
    this.sunrise,
    this.sunset,
    this.useBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    if (hourlyForecast.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter to next 24 hours and sort by time
    final now = DateTime.now();
    final filteredForecast = hourlyForecast
        .where((forecast) => forecast.time.toLocal().isAfter(now.subtract(const Duration(minutes: 30))))
        .take(24)
        .toList()
      ..sort((a, b) => a.time.toLocal().compareTo(b.time.toLocal()));

    if (filteredForecast.isEmpty) {
      return const SizedBox.shrink();
    }

    // Prepare data for the chart
    final List<FlSpot> probabilitySpots = [];
    final List<FlSpot> amountSpots = [];
    final List<String> timeLabels = [];

    for (int i = 0; i < filteredForecast.length; i++) {
      final forecast = filteredForecast[i];
      final time = forecast.time.toLocal();
      
      // Add probability data (0-100 scale)
      final probability = forecast.precipProbability ?? 0;
      probabilitySpots.add(FlSpot(i.toDouble(), probability.toDouble()));
      
      // Add amount data (convert to inches if needed)
      double amount = 0.0;
      if (forecast.precipAmount != null) {
        amount = forecast.precipAmount!;
        // Convert mm to inches if needed
        if (forecast.precipUnit == 'MM') {
          amount = amount / 25.4;
        }
      }
      amountSpots.add(FlSpot(i.toDouble(), amount));
      
      // Add time labels (every 6 hours)
      if (i % 6 == 0 || i == filteredForecast.length - 1) {
        timeLabels.add(DateFormat('ha').format(time));
      } else {
        timeLabels.add('');
      }
    }

    // Calculate max amount for right axis scaling
    final maxAmount = _getMaxAmount(amountSpots);

    return GlassCard(
      useBlur: useBlur,
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
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.textLight.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        reservedSize: 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value == 0) {
                            return const Text('');
                          }
                          final amountValue = (value / 100) * maxAmount;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${amountValue.toStringAsFixed(2)}"',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textLight.withValues(alpha: 0.7),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 6,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() < timeLabels.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                timeLabels[value.toInt()],
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textLight.withValues(alpha: 0.7),
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        reservedSize: 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${value.toInt()}%',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textLight.withValues(alpha: 0.7),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(
                        color: AppTheme.textLight.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      top: BorderSide(
                        color: AppTheme.textLight.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: AppTheme.textLight.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      right: BorderSide.none,
                    ),
                  ),
                  extraLinesData: const ExtraLinesData(
                    horizontalLines: [],
                    verticalLines: [],
                  ),
                  minX: 0,
                  maxX: (filteredForecast.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    // Probability line (left axis)
                    LineChartBarData(
                      spots: probabilitySpots,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha: 0.8),
                          Colors.blue.withValues(alpha: 0.4),
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withValues(alpha: 0.3),
                            Colors.blue.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                    // Amount line (right axis)
                    LineChartBarData(
                      spots: amountSpots.map((spot) => FlSpot(spot.x, (spot.y / maxAmount) * 100)).toList(),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withValues(alpha: 0.8),
                          Colors.amber.withValues(alpha: 0.4),
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.withValues(alpha: 0.3),
                            Colors.amber.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                  ],
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
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textLight.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  double _getMaxAmount(List<FlSpot> spots) {
    if (spots.isEmpty) return 0.5;
    final maxVal = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    
    // If max precipitation is very low, set a reasonable default for the axis.
    if (maxVal < 0.1) {
      return 0.5;
    }
    
    // Otherwise, round up to the next 0.1 and add a little padding.
    return (maxVal * 10).ceil() / 10.0 + 0.1;
  }
} 