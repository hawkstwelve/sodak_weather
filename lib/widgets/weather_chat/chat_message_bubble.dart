import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../constants/ui_constants.dart';

class ChatMessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;

  const ChatMessageBubble({
    super.key,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.spacingLarge),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryMedium,
              child: Icon(
                Icons.cloud,
                color: AppTheme.textLight,
                size: 20,
              ),
            ),
            const SizedBox(width: UIConstants.spacingMedium),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(UIConstants.spacingLarge),
              decoration: BoxDecoration(
                color: isUser 
                    ? Colors.white.withValues(alpha: 0.2) 
                    : Colors.grey[600]!.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isTyping
                        ? Row(
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textLight),
                                ),
                              ),
                              const SizedBox(width: UIConstants.spacingMedium),
                              Text(
                                'AI is analyzing weather data...',
                                style: AppTheme.bodyMedium,
                              ),
                            ],
                          )
                        : Text(
                            content,
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                const Shadow(
                                  blurRadius: 2,
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(height: UIConstants.spacingSmall),
                    Text(
                      _formatTimestamp(timestamp),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMedium,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
          ),
          if (isUser) ...[
            const SizedBox(width: UIConstants.spacingMedium),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryLight,
              child: Icon(
                Icons.person,
                color: AppTheme.textLight,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
} 