import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/assets/components/notification_service.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:engineering_project/pages/admin_notification_management.dart';
import 'package:engineering_project/providers/discount_code_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final Set<String> selectedNotifications = {};
  bool isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final specialColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : null;
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.email?.endsWith('@admin.com') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notifications),
        actions: [
          if (isSelectionMode) ...[
            IconButton(
              icon: Icon(Icons.visibility),
              onPressed: () {
                NotificationService.markMultipleAsRead(selectedNotifications.toList());
                setState(() {
                  selectedNotifications.clear();
                  isSelectionMode = false;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                NotificationService.deleteMultipleNotifications(selectedNotifications.toList());
                setState(() {
                  selectedNotifications.clear();
                  isSelectionMode = false;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  selectedNotifications.clear();
                  isSelectionMode = false;
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.select_all),
              onPressed: () {
                setState(() {
                  isSelectionMode = true;
                });
              },
            ),
          ],
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noNotifications,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.noNotificationsDesc,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index].data() as Map<String, dynamic>;
                  final isRead = notification['isRead'] ?? false;
                  final timestamp = (notification['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final notificationId = notifications[index].id;

                  return Dismissible(
                    key: Key(notificationId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (direction) {
                      NotificationService.deleteNotification(notificationId);
                    },
                    child: ListTile(
                      leading: isSelectionMode
                          ? Checkbox(
                              value: selectedNotifications.contains(notificationId),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    selectedNotifications.add(notificationId);
                                  } else {
                                    selectedNotifications.remove(notificationId);
                                  }
                                });
                              },
                            )
                          : CircleAvatar(
                              backgroundColor: isRead
                                  ? Colors.grey
                                  : (themeNotifier.isSpecialModeActive
                                      ? specialColor
                                      : (themeNotifier.isBlackMode
                                          ? Theme.of(context).colorScheme.secondary
                                          : Colors.red)),
                              child: Icon(
                                _getNotificationIcon(notification['type']),
                                color: Colors.white,
                              ),
                            ),
                      title: Text(
                        notification['title'] ?? 'Notification',
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification['message'] ?? ''),
                          SizedBox(height: 4),
                          Text(
                            _formatTimestamp(timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        if (isSelectionMode) {
                          setState(() {
                            if (selectedNotifications.contains(notificationId)) {
                              selectedNotifications.remove(notificationId);
                            } else {
                              selectedNotifications.add(notificationId);
                            }
                          });
                        } else {
                          if (!isRead) {
                            NotificationService.markAsRead(notificationId);
                          }
                          // Handle discount code notification
                          if (notification['type'] == 'promotion' && notification['discountCode'] != null) {
                            final discountProvider = Provider.of<DiscountCodeProvider>(context, listen: false);
                            discountProvider.saveDiscountFromNotification(notification);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Discount code saved to your promotions!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              ),
              if (isAdmin)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminNotificationManagement(),
                        ),
                      );
                    },
                    child: Icon(Icons.send),
                    tooltip: 'Send Notification',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag;
      case 'promotion':
        return Icons.local_offer;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
