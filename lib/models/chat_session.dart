import 'chat_message.dart';

class ChatSession {
  final String id;
  final List<ChatMessage> messages;
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.messages,
    required this.createdAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] ?? '',
      messages: (json['messages'] as List?)
              ?.map((message) => ChatMessage.fromJson(message))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'messages': messages.map((message) => message.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  ChatSession copyWith({
    String? id,
    List<ChatMessage>? messages,
    DateTime? createdAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper method to add a new message to the session
  ChatSession addMessage(ChatMessage message) {
    final updatedMessages = List<ChatMessage>.from(messages)..add(message);
    return copyWith(messages: updatedMessages);
  }

  // Helper method to get the last message
  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  // Helper method to get message count
  int get messageCount => messages.length;
} 