import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:engineering_project/assets/components/notification_service.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  // Check if OneSignal is configured
  void _checkOneSignalStatus(BuildContext context) {
    if (!NotificationService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OneSignal is not properly configured'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      // Get the current permission status
      final permissionStatus = OneSignal.Notifications.permissionNative;
      if (permissionStatus != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notifications are not authorized. Please enable them in settings.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Request',
              onPressed: () {
                OneSignal.Notifications.requestPermission(true);
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check OneSignal status when the page is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOneSignalStatus(context);
    });
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final specialColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : null;
    final l10n = AppLocalizations.of(context);

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
          // Test OneSignal notification button
          IconButton(
            icon: Icon(
              Icons.send,
              color: isDark ? Colors.white : Colors.black,
            ),
            tooltip: 'Test OneSignal Notification',
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                final username = user?.displayName ?? 'User';
                
                await NotificationService.sendToAllUsers(
                  title: 'Hello from OneSignal!',
                  message: 'This is a test notification for $username',
                  additionalData: {
                    'userId': user?.uid ?? 'anonymous',
                    'timestamp': DateTime.now().toIso8601String(),
                  }
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send test notification: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          // Mark all as read button
          IconButton(
            icon: Icon(
              Icons.done_all,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () async {
              try {
                await NotificationService.markAllAsRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tüm bildirimler okundu olarak işaretlendi'),
                      backgroundColor: themeNotifier.isSpecialModeActive
                          ? (specialColor ?? Colors.green)
                           : Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bildirimler işaretlenirken bir hata oluştu'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          // Clear all notifications button
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () async {
              try {
                await NotificationService.deleteAllNotifications();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.allNotificationsCleared),
                      backgroundColor: themeNotifier.isSpecialModeActive
                          ? (specialColor ?? Colors.red)
                          : Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error clearing notifications: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // OneSignal Status Banner
          if (!NotificationService.isConfigured)
            Container(
              width: double.infinity,
              color: Colors.orange.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OneSignal notifications are not configured properly. Some features may not work.',
                      style: TextStyle(color: isDark ? Colors.orange[300] : Colors.orange[800]),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      OneSignal.Notifications.requestPermission(true);
                    },
                    child: const Text('Enable'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
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

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
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
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final notification = snapshot.data!.docs[index];
              final data = notification.data() as Map<String, dynamic>;
              final timestamp = (data['timestamp'] as Timestamp).toDate();
              final bool isRead = data['isRead'] ?? false;

              return Dismissible(
                key: Key(notification.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) async {
                  await notification.reference.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.notificationDeleted),
                      backgroundColor: themeNotifier.isSpecialModeActive
                          ? (specialColor ?? Colors.red)
                          : Colors.red,
                    ),
                  );
                },
                child: Card(
                  elevation: 0,
                  color: isDark ? Colors.grey[900] : Colors.white,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(data['type'], themeNotifier, context).withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getNotificationIcon(data['type']),
                            color: _getNotificationColor(data['type'], themeNotifier, context),
                          ),
                        ),
                        if (!isRead)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      data['title'] ?? '',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          data['message'] ?? '',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        if (data['imageUrl'] != null) ...[
                          SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              data['imageUrl'],
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                        SizedBox(height: 4),
                        Text(
                          timeago.format(timestamp, locale: Localizations.localeOf(context).languageCode),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      if (!isRead) {
                        await NotificationService.markAsRead(notification.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
            },
          ),
        ),
      ],),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'welcome':
        return Icons.waving_hand;
      case 'product':
        return Icons.new_releases;
      case 'discount':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type, ThemeNotifier themeNotifier, BuildContext context) {
    if (themeNotifier.isSpecialModeActive) {
      return themeNotifier.getThemeColor(themeNotifier.specialTheme);
    }

    switch (type) {
      case 'welcome':
        return Colors.green;
      case 'product':
        return Colors.blue;
      case 'discount':
        return Colors.orange;
      case 'general':
        return Colors.blue;
      case 'targeted':
        return Colors.orange;
      case 'segment':
        return Colors.purple;
      default:
        return Colors.purple;
    }
  }
} 