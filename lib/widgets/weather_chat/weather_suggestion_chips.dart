import 'package:flutter/material.dart';
// import '../../theme/app_theme.dart';
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
      height: 40, // Increased from 32 to 40 to ensure text visibility
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
                priority: GlassCardPriority.prominent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: UIConstants.spacingMedium,
                  vertical: UIConstants.spacingSmall, // Increased from spacingTiny
                ),
                child: Center(
                  child: Text(
                    suggestions[index], 
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: Colors.white, // Explicitly set white text color
                      fontWeight: FontWeight.w500, // Make text slightly bolder for better visibility
                    ), 
                    textAlign: TextAlign.center,
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