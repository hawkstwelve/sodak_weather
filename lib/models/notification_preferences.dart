class NotificationPreferences {
  final List<String> enabledAlertTypes;
  final DoNotDisturb? doNotDisturb;
  final DateTime? lastUpdated;

  NotificationPreferences({
    required this.enabledAlertTypes,
    this.doNotDisturb,
    this.lastUpdated,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enabledAlertTypes: List<String>.from(json['enabledAlertTypes'] ?? []),
      doNotDisturb: json['doNotDisturb'] != null
          ? DoNotDisturb.fromJson(json['doNotDisturb'])
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabledAlertTypes': enabledAlertTypes,
        'doNotDisturb': doNotDisturb?.toJson(),
        'lastUpdated': lastUpdated?.toIso8601String(),
      };
}

class DoNotDisturb {
  final bool enabled;
  final int startHour;
  final int endHour;

  DoNotDisturb({
    required this.enabled,
    required this.startHour,
    required this.endHour,
  });

  factory DoNotDisturb.fromJson(Map<String, dynamic> json) {
    return DoNotDisturb(
      enabled: json['enabled'] ?? false,
      startHour: json['startHour'] ?? 22,
      endHour: json['endHour'] ?? 7,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'startHour': startHour,
        'endHour': endHour,
      };
} 