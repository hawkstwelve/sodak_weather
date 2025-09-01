import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass/glass_card.dart';
import '../constants/ui_constants.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.spacingXLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Color Selection Section
            GlassCard(
              priority: GlassCardPriority.standard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Primary Color',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _pickCustomColor(context, themeProvider, isPrimary: true),
                        child: const Text('Custom'),
                      ),
                    ],
                  ),
                  const SizedBox(height: UIConstants.spacingSmall),
                  Text(
                    'Used for buttons, highlights, and accent elements',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingMedium),
                  _ColorGrid(
                    colors: _primaryPalette,
                    selected: themeProvider.config.primary,
                    onSelect: (Color c) => themeProvider.setPrimary(c),
                  ),
                  const SizedBox(height: UIConstants.spacingXLarge),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Accent Color',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _pickCustomColor(context, themeProvider, isPrimary: false),
                        child: const Text('Custom'),
                      ),
                    ],
                  ),
                  const SizedBox(height: UIConstants.spacingSmall),
                  Text(
                    'Used for loading indicators and chart highlights',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingMedium),
                  _ColorGrid(
                    colors: _accentPalette,
                    selected: themeProvider.config.accent,
                    onSelect: (Color c) => themeProvider.setAccent(c),
                  ),
                ],
              ),
            ),
            const SizedBox(height: UIConstants.spacingXLarge),
            
            // Reset Section
            GlassCard(
              priority: GlassCardPriority.standard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reset to Defaults',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: UIConstants.spacingSmall),
                        Text(
                          'Restore the beautiful default color scheme',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => themeProvider.resetToDefaults(),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  void _pickCustomColor(BuildContext context, ThemeProvider provider, {required bool isPrimary}) {
    Color current = isPrimary ? provider.config.primary : provider.config.accent;
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        Color temp = current;
        return AlertDialog(
          title: Text(isPrimary ? 'Pick primary color' : 'Pick accent color'),
          content: SingleChildScrollView(child: BlockPicker(pickerColor: current, onColorChanged: (Color c) { temp = c; })),
          actions: [
            TextButton(onPressed: () { Navigator.of(ctx).pop(); }, child: const Text('Cancel')),
            TextButton(onPressed: () { Navigator.of(ctx).pop(); if (isPrimary) { provider.setPrimary(temp); } else { provider.setAccent(temp); } }, child: const Text('OK')),
          ],
        );
      },
    );
  }
}



class _ColorGrid extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelect;
  const _ColorGrid({required this.colors, required this.selected, required this.onSelect});
  
  @override
  Widget build(BuildContext context) {
    // Calculate optimal grid layout - 6 columns for 12 colors = 2 rows
    const int crossAxisCount = 6;
    const double spacing = UIConstants.spacingMedium;
    const double colorSize = 36.0; // Slightly larger for better touch targets
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.0,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final Color c = colors[index];
        final bool isSelected = c.toARGB32() == selected.toARGB32();
        
        return InkWell(
          onTap: () => onSelect(c),
          borderRadius: BorderRadius.circular(colorSize / 2),
          child: Container(
            width: colorSize,
            height: colorSize,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: c.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: isSelected ? Icon(
              Icons.check,
              color: _getContrastColor(c),
              size: 20,
            ) : null,
          ),
        );
      },
    );
  }
  
  // Helper method to get contrasting color for check icon
  Color _getContrastColor(Color backgroundColor) {
    // Simple luminance calculation for contrast
    final double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}



const List<Color> _primaryPalette = <Color>[
  Colors.indigo,
  Colors.blue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lime,
  Colors.orange,
  Colors.deepOrange,
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
];

const List<Color> _accentPalette = <Color>[
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.redAccent,
  Colors.pinkAccent,
  Colors.purpleAccent,
  Colors.indigoAccent,
  Colors.blueAccent,
  Colors.lightBlueAccent,
  Colors.tealAccent,
  Colors.greenAccent,
  Colors.limeAccent,
];


