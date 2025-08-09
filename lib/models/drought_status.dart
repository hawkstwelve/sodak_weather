import 'package:flutter/material.dart';

/// Represents drought status information for South Dakota
class DroughtStatus {
  final String category;
  final String description;
  final DateTime lastUpdated;
  final String mapUrl;
  final String? stateSpecificUrl;

  const DroughtStatus({
    required this.category,
    required this.description,
    required this.lastUpdated,
    required this.mapUrl,
    this.stateSpecificUrl,
  });

  /// Get the color associated with the drought category
  Color get categoryColor {
    switch (category.toUpperCase()) {
      case 'D0':
        return const Color(0xFFFFF2CC); // Abnormally Dry - Light yellow
      case 'D1':
        return const Color(0xFFFFE699); // Moderate Drought - Yellow
      case 'D2':
        return const Color(0xFFFFCC00); // Severe Drought - Orange
      case 'D3':
        return const Color(0xFFE69138); // Extreme Drought - Red-orange
      case 'D4':
        return const Color(0xFFCC0000); // Exceptional Drought - Red
      default:
        return const Color(0xFF90EE90); // No Drought - Light green
    }
  }

  /// Get a user-friendly description of the drought category
  String get categoryDescription {
    switch (category.toUpperCase()) {
      case 'D0':
        return 'Abnormally Dry';
      case 'D1':
        return 'Moderate Drought';
      case 'D2':
        return 'Severe Drought';
      case 'D3':
        return 'Extreme Drought';
      case 'D4':
        return 'Exceptional Drought';
      default:
        return 'No Drought';
    }
  }

  /// Create from JSON data
  factory DroughtStatus.fromJson(Map<String, dynamic> json) {
    return DroughtStatus(
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
      mapUrl: json['mapUrl'] ?? '',
      stateSpecificUrl: json['stateSpecificUrl'],
    );
  }

  /// Convert to JSON data
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'description': description,
      'lastUpdated': lastUpdated.toIso8601String(),
      'mapUrl': mapUrl,
      'stateSpecificUrl': stateSpecificUrl,
    };
  }
} 