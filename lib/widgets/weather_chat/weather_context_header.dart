import 'package:flutter/material.dart';
// import '../../theme/app_theme.dart';
import '../glass/glass_card.dart';
import '../../constants/ui_constants.dart';

class WeatherContextHeader extends StatelessWidget {
  final String cityName;
  final double? temperature;
  final String? condition;

  const WeatherContextHeader({
    super.key,
    required this.cityName,
    required this.temperature,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      priority: GlassCardPriority.prominent,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingXLarge),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cityName, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: UIConstants.spacingSmall),
                Row(
                  children: [
                    Text(temperature != null ? '${temperature!.round()}°' : 'N/A', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32)),
                    const SizedBox(width: UIConstants.spacingMedium),
                    Text(condition ?? 'Unknown', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Weather Chat', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: UIConstants.spacingSmall),
                Text('Ask me about the weather!', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 