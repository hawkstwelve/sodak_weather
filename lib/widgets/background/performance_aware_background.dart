import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'frosted_blob_background.dart';
import '../../models/theme_config.dart';

/// Performance-aware wrapper that automatically switches between
/// animated and static background based on device performance
class PerformanceAwareBackground extends StatefulWidget {
  final Widget child;
  final ThemeConfig themeConfig;

  const PerformanceAwareBackground({
    super.key,
    required this.child,
    required this.themeConfig,
  });

  @override
  State<PerformanceAwareBackground> createState() => _PerformanceAwareBackgroundState();
}

class _PerformanceAwareBackgroundState extends State<PerformanceAwareBackground> {
  bool _useAnimatedBackground = true;
  int _frameDropCount = 0;
  late final Ticker _performanceTicker;

  @override
  void initState() {
    super.initState();
    _setupPerformanceMonitoring();
  }

  void _setupPerformanceMonitoring() {
    _performanceTicker = Ticker((Duration elapsed) {
      // Monitor for frame drops
      final int currentFrame = elapsed.inMilliseconds ~/ 16; // 60fps = ~16ms per frame
      if (currentFrame > 0 && elapsed.inMilliseconds % 16 > 20) {
        _frameDropCount++;
        
        // If we detect consistent frame drops, switch to static background
        if (_frameDropCount > 10 && _useAnimatedBackground) {
          setState(() {
            _useAnimatedBackground = false;
          });
          debugPrint('Switched to static background due to performance');
        }
      }
      
      // Reset counter periodically
      if (currentFrame % 300 == 0) { // Every 5 seconds
        if (_frameDropCount < 3 && !_useAnimatedBackground) {
          setState(() {
            _useAnimatedBackground = true;
          });
          debugPrint('Switched back to animated background');
        }
        _frameDropCount = 0;
      }
    });
    
    _performanceTicker.start();
  }

  @override
  void dispose() {
    _performanceTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useAnimatedBackground) {
      return FrostedBlobBackground(
        themeConfig: widget.themeConfig,
        enableAnimation: true,
        child: widget.child,
      );
    } else {
      return SimpleFrostedBackground(
        themeConfig: widget.themeConfig,
        child: widget.child,
      );
    }
  }
}

/// Debug widget to manually control background type during development
class DebugBackgroundController extends StatefulWidget {
  final Widget child;
  final ThemeConfig themeConfig;

  const DebugBackgroundController({
    super.key,
    required this.child,
    required this.themeConfig,
  });

  @override
  State<DebugBackgroundController> createState() => _DebugBackgroundControllerState();
}

class _DebugBackgroundControllerState extends State<DebugBackgroundController> {
  BackgroundType _currentType = BackgroundType.animated;

  @override
  Widget build(BuildContext context) {
    Widget background;
    
    switch (_currentType) {
      case BackgroundType.animated:
        background = FrostedBlobBackground(
          themeConfig: widget.themeConfig,
          enableAnimation: true,
          child: widget.child,
        );
        break;
      case BackgroundType.static:
        background = SimpleFrostedBackground(
          themeConfig: widget.themeConfig,
          child: widget.child,
        );
        break;
      case BackgroundType.minimal:
        background = Container(
          color: const Color(0xFFF8F9FA),
          child: widget.child,
        );
        break;
    }

    return Stack(
      children: [
        background,
        Positioned(
          top: 50,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'BG Type',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                DropdownButton<BackgroundType>(
                  value: _currentType,
                  dropdownColor: Colors.black87,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  onChanged: (BackgroundType? value) {
                    if (value != null) {
                      setState(() {
                        _currentType = value;
                      });
                    }
                  },
                  items: BackgroundType.values.map((BackgroundType type) {
                    return DropdownMenuItem<BackgroundType>(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum BackgroundType {
  animated('Animated'),
  static('Static'),
  minimal('Minimal');

  const BackgroundType(this.displayName);
  final String displayName;
}
