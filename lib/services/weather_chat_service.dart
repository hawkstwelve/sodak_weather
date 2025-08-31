import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/service_constants.dart';
import '../models/chat_message.dart';

class WeatherChatService {
  static const String _functionName = 'weatherChat';
  static const int _cacheDurationMs = 60 * 60 * 1000; // 1 hour cache for similar questions
  static const String _cacheVersion = 'v1';

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Send a weather question to the AI chatbot
  /// Returns the AI response as a ChatMessage
  Future<ChatMessage> sendWeatherQuestion({
    required String question,
    required String location,
    String? userId,
  }) async {
    try {
      // Check cache for similar questions
      final cachedResponse = await _getCachedResponse(question, location);
      if (cachedResponse != null) {
        return cachedResponse;
      }

      // Prepare request data (minimal data as per plan)
      final requestData = {
        'question': question.trim(),
        'location': location,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Call Firebase Function with retry logic
      final response = await _retry(() async {
        try {
          final callable = _functions.httpsCallable(_functionName);
          final result = await callable.call(requestData).timeout(ServiceConstants.requestTimeout);
          return result.data;
        } catch (e) {
          rethrow;
        }
      });

      // Parse response
      if (response == null) {
        throw Exception('No response received from AI service');
      }

      final aiResponse = response['result'] ?? 'No response generated';
      
      // Log the response for debugging
      
      // Create chat message
      final chatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        timestamp: DateTime.now(),
        isUser: false,
        weatherContext: location,
      );

      // Cache the response
      await _cacheResponse(question, location, chatMessage);

      return chatMessage;
    } on FirebaseFunctionsException catch (e) {
      throw _handleFirebaseException(e);
    } on SocketException catch (_) {
      throw Exception('Network connection failed. Please check your internet connection.');
    } on HandshakeException catch (_) {
      throw Exception('Secure connection failed. Please try again.');
    } on TimeoutException catch (_) {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      throw Exception('Error sending weather question: $e');
    }
  }

  /// Retry logic following the established pattern
  Future<T> _retry<T>(Future<T> Function() fn) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (attempt > ServiceConstants.maxRetries) rethrow;
        await Future.delayed(ServiceConstants.retryDelay);
      }
    }
  }

  /// Handle Firebase Functions exceptions
  Exception _handleFirebaseException(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return Exception('Authentication required. Please sign in.');
      case 'resource-exhausted':
        return Exception('Rate limit exceeded. Please try again later.');
      case 'invalid-argument':
        return Exception('Invalid request. Please check your question.');
      case 'internal':
        return Exception('Service temporarily unavailable. Please try again.');
      case 'unavailable':
        return Exception('Service unavailable. Please try again later.');
      default:
        return Exception('Service error: ${e.message}');
    }
  }

  /// Simple cache key generation for similar questions
  String _generateCacheKey(String question, String location) {
    final normalizedQuestion = question.toLowerCase().trim();
    final normalizedLocation = location.toLowerCase().trim();
    return 'chat_${_cacheVersion}_${normalizedQuestion}_$normalizedLocation';
  }

  /// Get cached response for similar questions
  Future<ChatMessage?> _getCachedResponse(String question, String location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(question, location);
      final cacheTimeKey = '${cacheKey}_time';
      final now = DateTime.now().millisecondsSinceEpoch;

      final cached = prefs.getString(cacheKey);
      final cachedTime = prefs.getInt(cacheTimeKey);

      if (cached != null && cachedTime != null && now - cachedTime < _cacheDurationMs) {
        final cachedData = json.decode(cached);
        return ChatMessage.fromJson(cachedData);
      }

      return null;
    } catch (e) {
      // If cache fails, continue without cache
      return null;
    }
  }

  /// Cache response for future similar questions
  Future<void> _cacheResponse(String question, String location, ChatMessage response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(question, location);
      final cacheTimeKey = '${cacheKey}_time';
      final now = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(cacheKey, json.encode(response.toJson()));
      await prefs.setInt(cacheTimeKey, now);
    } catch (e) {
      // If caching fails, continue without caching
      // Don't throw error as caching is not critical
    }
  }

  /// Clear chat cache (useful for testing or when cache becomes stale)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith('chat_${_cacheVersion}_')) {
          await prefs.remove(key);
          await prefs.remove('${key}_time');
        }
      }
    } catch (e) {
      // If cache clearing fails, continue
    }
  }

  /// Get cache statistics (useful for debugging)
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int chatCacheEntries = 0;
      
      for (final key in keys) {
        if (key.startsWith('chat_${_cacheVersion}_') && !key.endsWith('_time')) {
          chatCacheEntries++;
        }
      }
      
      return {
        'chatCacheEntries': chatCacheEntries,
        'cacheVersion': _cacheVersion,
        'cacheDurationMs': _cacheDurationMs,
      };
    } catch (e) {
      return {
        'error': 'Failed to get cache stats: $e',
      };
    }
  }
} 