import 'package:flutter/material.dart';
// import '../../theme/app_theme.dart';
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
            CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.primary, child: Icon(Icons.cloud, color: Theme.of(context).colorScheme.onPrimary, size: 20)),
            const SizedBox(width: UIConstants.spacingMedium),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(UIConstants.spacingLarge),
              decoration: BoxDecoration(
                color: isUser ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onSurface),
                              ),
                            ),
                            const SizedBox(width: UIConstants.spacingMedium),
                            Text('AI is analyzing weather data...', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        )
                      : Text(
                          content,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: UIConstants.spacingMedium),
            CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.tertiary, child: Icon(Icons.person, color: Theme.of(context).colorScheme.onTertiary, size: 20)),
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