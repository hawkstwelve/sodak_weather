import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/weather_chat_service.dart';

/// Manages the state for weather chat functionality.
///
/// This provider handles chat sessions, message history, loading states,
/// and error handling for the AI weather chatbot.
class WeatherChatProvider with ChangeNotifier {
  final WeatherChatService _chatService = WeatherChatService();

  // Private state variables
  ChatSession? _currentSession;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isTyping = false; // Indicates AI is generating response

  // Public getters to access state
  ChatSession? get currentSession => _currentSession;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isTyping => _isTyping;
  bool get hasMessages => _messages.isNotEmpty;
  int get messageCount => _messages.length;

  /// Initialize a new chat session
  void initializeSession() {
    _currentSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      messages: [],
      createdAt: DateTime.now(),
    );
    _messages = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Add a user message to the chat
  void addUserMessage(String content, String location) {
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      timestamp: DateTime.now(),
      isUser: true,
      weatherContext: location,
    );

    _messages.add(userMessage);
    _updateCurrentSession();
    notifyListeners();
  }

  /// Send a weather question to the AI and handle the response
  Future<void> sendWeatherQuestion({
    required String question,
    required String location,
  }) async {
    if (question.trim().isEmpty) return;

    // Set typing state
    _isTyping = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Send question to AI service
      final aiResponse = await _chatService.sendWeatherQuestion(
        question: question,
        location: location,
      );

      // Log the AI response for debugging
      
      // Add AI response to messages
      _messages.add(aiResponse);
      _updateCurrentSession();
      
    } catch (e) {
      // Handle error and add error message
      _errorMessage = e.toString();
      
      // Add error message as AI response
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I encountered an error while processing your question. Please try again.',
        timestamp: DateTime.now(),
        isUser: false,
        weatherContext: location,
      );
      
      _messages.add(errorMessage);
      _updateCurrentSession();
      
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  /// Update the current session with new messages
  void _updateCurrentSession() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        messages: List.from(_messages),
      );
    }
  }

  /// Clear the current chat session
  void clearSession() {
    _messages = [];
    _currentSession = null;
    _errorMessage = null;
    _isTyping = false;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get the last message in the chat
  ChatMessage? get lastMessage => _messages.isNotEmpty ? _messages.last : null;

  /// Get user messages only
  List<ChatMessage> get userMessages => _messages.where((msg) => msg.isUser).toList();

  /// Get AI messages only
  List<ChatMessage> get aiMessages => _messages.where((msg) => !msg.isUser).toList();

  /// Check if the last message is from the user (waiting for AI response)
  bool get isWaitingForResponse => 
      _messages.isNotEmpty && _messages.last.isUser && !_isTyping;

  /// Get chat statistics
  Map<String, dynamic> get chatStats => {
    'totalMessages': _messages.length,
    'userMessages': userMessages.length,
    'aiMessages': aiMessages.length,
    'sessionDuration': _currentSession != null 
        ? DateTime.now().difference(_currentSession!.createdAt).inMinutes 
        : 0,
  };

  /// Load a chat session from JSON (for persistence)
  void loadSession(ChatSession session) {
    _currentSession = session;
    _messages = List.from(session.messages);
    _errorMessage = null;
    _isTyping = false;
    notifyListeners();
  }

  /// Export current session as JSON
  Map<String, dynamic>? exportSession() {
    return _currentSession?.toJson();
  }

  /// Check if a message is recent (within last 5 minutes)
  bool isMessageRecent(ChatMessage message) {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    return message.timestamp.isAfter(fiveMinutesAgo);
  }

  /// Get messages from a specific time period
  List<ChatMessage> getMessagesFromPeriod({
    required DateTime start,
    required DateTime end,
  }) {
    return _messages.where((message) => 
        message.timestamp.isAfter(start) && 
        message.timestamp.isBefore(end)
    ).toList();
  }

  /// Get messages containing specific text (for search functionality)
  List<ChatMessage> searchMessages(String query) {
    if (query.trim().isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    return _messages.where((message) => 
        message.content.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  /// Clear chat cache (delegates to service)
  Future<void> clearCache() async {
    try {
      await _chatService.clearCache();
    } catch (e) {
      _errorMessage = 'Failed to clear cache: $e';
      notifyListeners();
    }
  }

  /// Get cache statistics (delegates to service)
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      return await _chatService.getCacheStats();
    } catch (e) {
      return {'error': 'Failed to get cache stats: $e'};
    }
  }

  /// Check if the provider is in a valid state
  bool get isValidState => 
      _messages.isNotEmpty || _currentSession != null || _isTyping;

  /// Reset the provider to initial state
  void reset() {
    _currentSession = null;
    _messages = [];
    _errorMessage = null;
    _isTyping = false;
    _isLoading = false;
    notifyListeners();
  }
} 