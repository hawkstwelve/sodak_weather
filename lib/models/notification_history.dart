class NotificationHistory {
  final String alertId;
  final String event;
  final DateTime sentAt;
  final bool read;
  final List<String> notifiedDevices;

  NotificationHistory({
    required this.alertId,
    required this.event,
    required this.sentAt,
    required this.read,
    required this.notifiedDevices,
  });

  factory NotificationHistory.fromJson(Map<String, dynamic> json) {
    return NotificationHistory(
      alertId: json['alertId'] ?? '',
      event: json['event'] ?? '',
      sentAt: DateTime.parse(json['sentAt']),
      read: json['read'] ?? false,
      notifiedDevices: List<String>.from(json['notifiedDevices'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'alertId': alertId,
        'event': event,
        'sentAt': sentAt.toIso8601String(),
        'read': read,
        'notifiedDevices': notifiedDevices,
      };
} 