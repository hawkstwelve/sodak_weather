import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sodak_weather/widgets/glass/glass_container.dart';
import '../models/sd_city.dart';
import '../providers/weather_provider.dart';
import '../services/afd_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/glass/frosted_background.dart';

class AFDScreen extends StatefulWidget {
  final List<Color> gradientColors;
  final Widget? citySelector;
  final Function(int)? onNavigate;
  final String currentScreenId;

  const AFDScreen({
    super.key,
    required this.gradientColors,
    this.citySelector,
    this.onNavigate,
    required this.currentScreenId,
  });

  @override
  State<AFDScreen> createState() => _AFDScreenState();
}

class _AFDScreenState extends State<AFDScreen> {
  String? _afdText;
  bool _isLoading = false;
  String? _errorMessage;
  SDCity? _lastFetchedCity; // Used to prevent redundant fetches

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final currentCity = weatherProvider.selectedCity;

    // Fetch data only if the city has changed since the last fetch.
    if (_lastFetchedCity == null || _lastFetchedCity!.name != currentCity.name) {
      _lastFetchedCity = currentCity;
      _fetchAFD(currentCity);
    }
  }

  Future<void> _fetchAFD(SDCity city) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final afdResult = await AfdService.fetchAfd(city);
      if (mounted) {
        setState(() {
          _afdText = afdResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the selected city from the provider to pass to the AppDrawer
    final selectedCity = Provider.of<WeatherProvider>(context, listen: false).selectedCity;
    
    return FrostedPageScaffold(
      backgroundColor: Colors.transparent,
      gradientColors: widget.gradientColors,
      appBar: AppBar(
        title: const Text(
          'Area Forecast Discussion',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textLight,
        elevation: 0,
        titleSpacing: NavigationToolbar.kMiddleSpacing,
        actions: [
          if (widget.citySelector != null) widget.citySelector!,
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(
        gradientColors: widget.gradientColors,
        selectedCity: selectedCity,
        currentScreenId: widget.currentScreenId,
        onNavigationTap: (index) => widget.onNavigate?.call(index),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.loadingIndicatorColor))
          : SafeArea(
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.92,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: GlassContainer(
                      useBlur: false,
                      padding: const EdgeInsets.all(20.0),
                      child: _errorMessage != null
                          ? Text(_errorMessage!, style: AppTheme.bodyMedium)
                          : SingleChildScrollView(
                              child: SizedBox(
                                width: double.infinity,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: SelectableText(
                                    _cleanAfdText(_afdText ?? 'No AFD available.'),
                                    style: AppTheme.bodyMedium,
                                    textAlign: TextAlign.left,
                                    textDirection: TextDirection.ltr,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  String _cleanAfdText(String text) {
    // Clean text while preserving paragraph structure
    return text
        .replaceAll(RegExp(r'\r\n'), '\n') // Normalize Windows line breaks
        .replaceAll(RegExp(r'\r'), '\n') // Normalize Mac line breaks
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Replace multiple spaces/tabs with single space
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n') // Replace multiple blank lines with double line break
        .replaceAll(RegExp(r'\.\s*\.'), '.') // Fix double periods
        .replaceAll(RegExp(r'\n(?=\w)'), ' ') // Replace single line breaks within paragraphs with space
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Ensure consistent paragraph breaks
        .trim(); // Remove leading/trailing whitespace
  }
}
