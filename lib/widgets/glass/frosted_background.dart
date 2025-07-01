import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';

/// Creates a frosted background with gradient effect
class FrostedBackground extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final BoxConstraints? constraints;

  const FrostedBackground({
    required this.child,
    this.gradientColors = UIConstants.frostedGradient,
    this.constraints,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: constraints,
      decoration: BoxDecoration(
        // Semi-transparent gradient that creates a frosted glass effect
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

/// A performance-optimized page wrapper with a frosted background effect
class FrostedPageScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final List<Color> gradientColors;

  const FrostedPageScaffold({
    required this.body,
    this.appBar,
    this.backgroundColor,
    this.drawer,
    this.bottomNavigationBar,
    this.gradientColors = const [Color(0x15FFFFFF), Color(0x10FFFFFF)],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: backgroundColor,
      appBar: appBar,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      body: FrostedBackground(gradientColors: gradientColors, child: body),
    );
  }
}
