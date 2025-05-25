import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final specialColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : null;
    final l10n = AppLocalizations.of(context)!;

    // Example notifications (will be fetched from Firebase later)
    final List<NotificationItem> notifications = [
      NotificationItem(
        title: l10n.welcomeNotification,
        message: l10n.welcomeNotificationDesc,
        time: DateTime.now().subtract(Duration(minutes: 5)),
        type: NotificationType.welcome,
      ),
      NotificationItem(
        title: l10n.newProductNotification,
        message: l10n.newProductNotificationDesc,
        time: DateTime.now().subtract(Duration(hours: 2)),
        type: NotificationType.product,
      ),
      NotificationItem(
        title: l10n.discountNotification,
        message: l10n.discountNotificationDesc,
        time: DateTime.now().subtract(Duration(days: 1)),
        type: NotificationType.discount,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          l10n.notifications,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              // Function to delete all notifications will be added
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.allNotificationsCleared),
                  backgroundColor: themeNotifier.isSpecialModeActive
                      ? specialColor
                      : Colors.red,
                ),
              );
            },
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    l10n.noNotifications,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    l10n.noNotificationsDesc,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: Key(notification.title + index.toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    // Function to delete notification will be added
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.notificationDeleted),
                        backgroundColor: themeNotifier.isSpecialModeActive
                            ? specialColor
                            : Colors.red,
                      ),
                    );
                  },
                  child: Card(
                    elevation: 0,
                    color: isDark ? Colors.grey[900] : Colors.white,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: notification.type.color(themeNotifier, context).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          notification.type.icon,
                          color: notification.type.color(themeNotifier, context),
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _formatTime(context, notification.time),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Function to handle notification tap will be added
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(BuildContext context, DateTime time) {
    final l10n = AppLocalizations.of(context)!;
    final difference = DateTime.now().difference(time);
    
    if (difference.inMinutes < 60) {
      return l10n.minutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.hoursAgo(difference.inHours);
    } else {
      return l10n.daysAgo(difference.inDays);
    }
  }
}

enum NotificationType {
  welcome,
  product,
  discount,
}

extension NotificationTypeExtension on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.welcome:
        return Icons.waving_hand;
      case NotificationType.product:
        return Icons.new_releases;
      case NotificationType.discount:
        return Icons.local_offer;
    }
  }

  Color color(ThemeNotifier themeNotifier, BuildContext context) {
    if (themeNotifier.isSpecialModeActive) {
      return themeNotifier.getThemeColor(themeNotifier.specialTheme) ?? Colors.blue;
    }

    switch (this) {
      case NotificationType.welcome:
        return Colors.green;
      case NotificationType.product:
        return Colors.blue;
      case NotificationType.discount:
        return Colors.orange;
    }
  }
}

class NotificationItem {
  final String title;
  final String message;
  final DateTime time;
  final NotificationType type;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
  });
} 