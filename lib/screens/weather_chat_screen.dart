import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_chat_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/weather_chat/weather_suggestion_chips.dart';
import '../widgets/weather_chat/chat_message_bubble.dart';

class WeatherChatScreen extends StatefulWidget {
  const WeatherChatScreen({super.key});

  @override
  State<WeatherChatScreen> createState() => _WeatherChatScreenState();
}

class _WeatherChatScreenState extends State<WeatherChatScreen> with WidgetsBindingObserver {
  // Scroll controller for auto-scrolling
  final ScrollController _scrollController = ScrollController();

  // Add persistent TextEditingController and FocusNode
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Weather question suggestions
  static const List<String> _suggestions = [
    "What's the temperature today?",
    "Will it rain this weekend?",
    "How's the wind today?",
    "Any weather alerts?",
    "Good day for outdoor activities?",
    "What's the forecast for tomorrow?",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Add listener to focus node to unfocus when screen loses focus
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Keyboard should be dismissed when focus is lost
        FocusScope.of(context).unfocus();
      }
    });
    
    // Initialize chat session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherChatProvider>().initializeSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.unfocus();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Unfocus when app goes to background or becomes inactive
      FocusScope.of(context).unfocus();
    }
  }

  /// Scroll to the bottom of the chat with animation
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weatherData = weatherProvider.weatherData;
    final currentConditions = weatherData?.currentConditions;
    final gradient = AppTheme.getGradientForCondition(currentConditions?.textDescription);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Chat interface
            Expanded(
              child: _buildChatInterface(),
            ),
            
            // Weather suggestion chips
            WeatherSuggestionChips(
              suggestions: _suggestions,
              onSuggestionTap: _handleSuggestionTap,
            ),
            
            // Spacing between suggestions and input
            const SizedBox(height: 12),
            
            // Custom input field
            _buildCustomInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    return Consumer<WeatherChatProvider>(
      builder: (context, chatProvider, child) {
        // Auto-scroll when messages change or typing state changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (chatProvider.messages.isNotEmpty || chatProvider.isTyping) {
            _scrollToBottom();
          }
        });

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: chatProvider.messages.length + (chatProvider.isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < chatProvider.messages.length) {
                    final message = chatProvider.messages[index];
                    return ChatMessageBubble(
                      content: message.content,
                      isUser: message.isUser,
                      timestamp: message.timestamp,
                    );
                  } else {
                    // Typing indicator
                    return ChatMessageBubble(
                      content: 'AI is analyzing weather data...',
                      isUser: false,
                      timestamp: DateTime.now(),
                      isTyping: true,
                    );
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleUserMessage(String text) {
    final chatProvider = context.read<WeatherChatProvider>();
    final weatherProvider = context.read<WeatherProvider>();
    
    // Get location from weather provider
    final location = weatherProvider.isUsingLocation 
        ? 'Current Location'
        : weatherProvider.selectedCity.name;

    // Add user message to provider first
    chatProvider.addUserMessage(text, location);
    
    // Unfocus keyboard when sending message
    _unfocusKeyboard();
    
    // Scroll to bottom after user message is added
    _scrollToBottom();
    
    // Then send the question
    chatProvider.sendWeatherQuestion(
      question: text,
      location: location,
    );
  }

  void _handleSuggestionTap(String suggestion) {
    // Unfocus keyboard when tapping suggestions
    _unfocusKeyboard();
    _handleUserMessage(suggestion);
  }

  /// Unfocus keyboard and clear focus
  void _unfocusKeyboard() {
    FocusScope.of(context).unfocus();
    _focusNode.unfocus();
  }

  Widget _buildCustomInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Ask about the weather...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  _handleUserMessage(text);
                  _textController.clear();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () {
              final text = _textController.text.trim();
              if (text.isNotEmpty) {
                _handleUserMessage(text);
                _textController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
} 