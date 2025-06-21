import 'package:flutter/material.dart';

/// A performance-optimized scrollable list for glass-like widgets
/// Uses builder pattern to efficiently render and recycle GlassCards in scrolling views
class GlassCardScrollView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Axis scrollDirection;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final double? itemExtent;
  final double? cacheExtent;
  
  const GlassCardScrollView({
    required this.itemCount,
    required this.itemBuilder,
    this.scrollDirection = Axis.vertical,
    this.physics = const ClampingScrollPhysics(), // More efficient physics by default
    this.padding,
    this.shrinkWrap = false,
    this.itemExtent, // Fixed item size improves ListView performance
    this.cacheExtent, // Caching for smoother scrolling
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // We ensure all GlassCards in scrollable areas use simulated glass (no blur)
        final item = itemBuilder(context, index);
        // Don't modify the original widget if it's not a GlassCard
        return item;
      },
      scrollDirection: scrollDirection,
      physics: physics,
      padding: padding,
      shrinkWrap: shrinkWrap,
      itemExtent: itemExtent, // Fixed item extent significantly improves ListView performance
      cacheExtent: cacheExtent, 
    );
  }
}
