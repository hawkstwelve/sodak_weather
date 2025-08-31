import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/backend_service.dart';
// import '../theme/app_theme.dart';
import '../widgets/glass/glass_card.dart';
// import '../providers/weather_provider.dart';
import '../constants/ui_constants.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotificationHistory();
  }

  Future<void> _loadNotificationHistory() async {
    // Check if widget is still mounted before calling setState
    if (!mounted) return;
    
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final backendService = Provider.of<BackendService>(context, listen: false);
      final notifications = await backendService.loadNotificationHistory();
      
      // Check if widget is still mounted before calling setState
      if (!mounted) return;
      
      setState(() {
        _notifications = notifications.map((n) => n.toJson()).toList();
        _loading = false;
      });
    } catch (e) {
      // Check if widget is still mounted before calling setState
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // final weatherProvider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _buildMainContainer(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Notification History'),
      backgroundColor: Colors.transparent,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadNotificationHistory,
        ),
      ],
    );
  }

  Widget _buildMainContainer() {
    return SafeArea(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.95,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: GlassCard(
              priority: GlassCardPriority.prominent,
              contentPadding: const EdgeInsets.all(UIConstants.spacingXXXLarge),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoadingState();
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildNotificationList();
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error loading notifications', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: UIConstants.spacingStandard),
          Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: UIConstants.spacingXLarge),
          ElevatedButton(
            onPressed: _loadNotificationHistory,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: UIConstants.iconSizeLarge, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(height: UIConstants.spacingXLarge),
          Text('No notifications yet', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: UIConstants.spacingStandard),
          Text('Weather alerts will appear here when received', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _loadNotificationHistory,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _notifications.length,
        itemBuilder: (context, index) => _buildNotificationItem(_notifications[index]),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final alertType = notification['event'] ?? notification['alertType'] ?? 'Unknown';
    final areaDesc = notification['areaDesc'] ?? 'Unknown area';
    final sentAt = notification['sentAt'];
    
    final timestamp = _parseTimestamp(sentAt);

    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.spacingStandard),
      color: Colors.white.withValues(alpha: UIConstants.opacityVeryLow),
      child: ListTile(
        title: Text(
          alertType,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: _buildNotificationSubtitle(areaDesc, timestamp),
        leading: _getAlertIcon(alertType),
      ),
    );
  }

  Widget _buildNotificationSubtitle(String areaDesc, DateTime? timestamp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(areaDesc, style: Theme.of(context).textTheme.bodyMedium),
        if (timestamp != null)
          Text(_formatTimestamp(timestamp), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  DateTime? _parseTimestamp(dynamic sentAt) {
    if (sentAt == null) return null;
    
    if (sentAt is Timestamp) {
      return sentAt.toDate();
    } else if (sentAt is String) {
      return DateTime.tryParse(sentAt);
    } else if (sentAt is Map<String, dynamic>) {
      // Handle Firestore server timestamp format
      if (sentAt['_seconds'] != null) {
        final seconds = sentAt['_seconds'] as int;
        final nanoseconds = sentAt['_nanoseconds'] as int? ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanoseconds / 1000000).round());
      }
    }
    
    return null;
  }

  Widget _getAlertIcon(String alertType) {
    IconData iconData;
    Color iconColor;

    switch (alertType.toLowerCase()) {
      case 'severe thunderstorm warning':
      case 'severe thunderstorm watch':
        iconData = Icons.thunderstorm;
        iconColor = Colors.orange;
        break;
      case 'tornado warning':
      case 'tornado watch':
        iconData = Icons.rotate_right;
        iconColor = Colors.red;
        break;
      case 'extreme heat warning':
        iconData = Icons.thermostat;
        iconColor = Colors.red;
        break;
      case 'winter storm warning':
      case 'blizzard warning':
        iconData = Icons.ac_unit;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.warning;
        iconColor = Colors.yellow;
    }

    return Icon(iconData, color: iconColor, size: 24);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
} 