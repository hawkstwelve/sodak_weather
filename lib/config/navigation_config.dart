import 'package:flutter/material.dart';

/// Represents a single navigation item in the app drawer
class NavigationItem {
  final String title;
  final IconData icon;
  final String screenId;
  final int index;

  const NavigationItem({
    required this.title,
    required this.icon,
    required this.screenId,
    required this.index,
  });
}

/// Centralized navigation configuration for the app
class NavigationConfig {
  /// All available navigation items in the app
  static const List<NavigationItem> items = [
    NavigationItem(
      title: 'Weather',
      icon: Icons.cloud,
      screenId: 'weather',
      index: 0,
    ),
    NavigationItem(
      title: 'Radar',
      icon: Icons.radar,
      screenId: 'radar',
      index: 1,
    ),
    NavigationItem(
      title: 'Area Forecast Discussion',
      icon: Icons.article,
      screenId: 'afd',
      index: 2,
    ),
    NavigationItem(
      title: 'Storm Outlooks',
      icon: Icons.warning,
      screenId: 'spc_outlooks',
      index: 3,
    ),
    NavigationItem(
      title: 'Historical Almanac',
      icon: Icons.history,
      screenId: 'almanac',
      index: 4,
    ),
    NavigationItem(
      title: 'Settings',
      icon: Icons.settings,
      screenId: 'settings',
      index: 5,
    ),
  ];

  /// Get a navigation item by its screen ID
  static NavigationItem? getItemByScreenId(String screenId) {
    try {
      return items.firstWhere((item) => item.screenId == screenId);
    } catch (e) {
      return null;
    }
  }

  /// Get a navigation item by its index
  static NavigationItem? getItemByIndex(int index) {
    try {
      return items.firstWhere((item) => item.index == index);
    } catch (e) {
      return null;
    }
  }

  /// Check if a screen ID is valid
  static bool isValidScreenId(String screenId) {
    return items.any((item) => item.screenId == screenId);
  }
} 