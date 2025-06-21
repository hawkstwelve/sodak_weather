# Glass Card Usage Best Practices

This document outlines the best practices for using the optimized `GlassCard` and related components in the SoDak Weather app to maintain performance while keeping the visual design consistent.

## Table of Contents
1. [Performance Considerations](#performance-considerations)
2. [When to Use Blur vs. Simulated Glass](#when-to-use-blur-vs-simulated-glass)
3. [Usage in Scrollable Areas](#usage-in-scrollable-areas)
4. [Usage in Static Areas](#usage-in-static-areas)
5. [Pre-Generated Backgrounds](#pre-generated-backgrounds)

## Performance Considerations

The `BackdropFilter` widget in Flutter, which provides the blur effect, is computationally expensive. Each instance requires a separate readback from the GPU, which can significantly impact performance, especially when multiple instances are used or when they're in scrolling views.

## When to Use Blur vs. Simulated Glass

### Use `useBlur: true` (Real Blur) For:
- Static, non-scrolling UI elements
- Important, prominent cards that are always visible
- Headers or persistent elements
- Limited to 1-3 per screen for optimal performance

### Use `useBlur: false` (Simulated Glass) For:
- Any cards in scrollable lists
- Cards that appear in grids
- Bottom sheets or modals
- Secondary UI elements
- When multiple glass cards appear on the same screen

## Usage in Scrollable Areas

For lists containing glass cards:

```dart
// Example of using glass cards in a ListView
ListView.builder(
  itemCount: items.length,
  physics: const ClampingScrollPhysics(), // More efficient physics
  itemExtent: 100.0, // Fixed item size improves performance
  itemBuilder: (context, index) {
    return GlassCard(
      useBlur: false, // Always use false in scrolling views
      child: YourCardContent(),
    );
  },
)
```

Or better yet, use the optimized scroll view:

```dart
GlassCardScrollView(
  itemCount: items.length,
  itemExtent: 100.0,
  itemBuilder: (context, index) {
    return GlassCard(
      useBlur: false,
      child: YourCardContent(),
    );
  },
)
```

## Usage in Static Areas

For important, non-scrolling areas:

```dart
// For prominent UI elements, limited blur is acceptable
GlassCard(
  useBlur: true, // Use real blur for important UI components
  child: YourImportantWidget(),
)
```

## Pre-Generated Backgrounds

For screens with multiple glass elements, use a frosted background for the whole screen:

```dart
FrostedPageScaffold(
  body: Column(
    children: [
      // Cards no longer need blur since the background is already "frosted"
      GlassCard(
        useBlur: false,
        child: Text('Weather Information'),
      ),
      GlassCard(
        useBlur: false,
        child: Text('Forecast'),
      ),
    ],
  ),
)
```

Or use the glass background generator:

```dart
// Pre-generate a frosted container
Container(
  decoration: GlassBackgroundGenerator.createFrostedGlassBackground(
    context: context,
    baseColor: Colors.blue,
    opacity: 0.1,
  ),
  child: YourContent(),
)
```

By following these best practices, we can maintain the visual design of the app while significantly improving performance and reducing jank.
