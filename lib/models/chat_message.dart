class ChatMessage {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isUser;
  final String? weatherContext;

  ChatMessage({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isUser,
    this.weatherContext,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      isUser: json['isUser'] ?? false,
      weatherContext: json['weatherContext'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isUser': isUser,
        'weatherContext': weatherContext,
      };

  ChatMessage copyWith({
    String? id,
    String? content,
    DateTime? timestamp,
    bool? isUser,
    String? weatherContext,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isUser: isUser ?? this.isUser,
      weatherContext: weatherContext ?? this.weatherContext,
    );
  }
} 