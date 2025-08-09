import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../glass/glass_card.dart';
import '../../constants/ui_constants.dart';

class WeatherSuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;

  const WeatherSuggestionChips({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacingLarge),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: UIConstants.spacingSmall),
            child: GestureDetector(
              onTap: () => onSuggestionTap(suggestions[index]),
              child: GlassCard(
                useBlur: true,
                opacity: UIConstants.opacityVeryLow,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: UIConstants.spacingMedium,
                      vertical: UIConstants.spacingTiny,
                    ),
                    child: Text(
                      suggestions[index],
                      style: AppTheme.bodyMedium.copyWith(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 