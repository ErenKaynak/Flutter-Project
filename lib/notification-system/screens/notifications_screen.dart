import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../widgets/notification_tile.dart';
import '../../pages/theme_notifier.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: themeColor,
        elevation: isDark ? 0 : 2,
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: NotificationService().getUserNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationTile(
                notification: notification,
                onTap: () async {
                  // Mark as read
                  await NotificationService().markNotificationAsRead(
                    userId,
                    notification.id,
                  );

                  // Handle notification tap based on type
                  if (notification.type == NotificationType.discount) {
                    // Navigate to discounts & promotions tab
                    // You'll need to implement this navigation
                    // Navigator.pushNamed(context, '/discounts');
                  }
                },
                onDismiss: () async {
                  // Delete notification
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('notifications')
                      .doc(notification.id)
                      .delete();
                },
              );
            },
          );
        },
      ),
    );
  }
} 