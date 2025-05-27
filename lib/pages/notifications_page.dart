import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:engineering_project/assets/components/notification_service.dart';

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
                          ? specialColor
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
                final QuerySnapshot notificationsSnapshot = await FirebaseFirestore.instance
                    .collection('notifications')
                    .get();

                for (var doc in notificationsSnapshot.docs) {
                  await doc.reference.delete();
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.allNotificationsCleared),
                    backgroundColor: themeNotifier.isSpecialModeActive
                        ? specialColor
                        : Colors.red,
                  ),
                );
              } catch (e) {
                print('Error clearing notifications: $e');
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
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
                    leading: Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(data['type'], themeNotifier, context).withOpacity(0.1),
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
      return themeNotifier.getThemeColor(themeNotifier.specialTheme) ?? Colors.blue;
    }

    switch (type) {
      case 'welcome':
        return Colors.green;
      case 'product':
        return Colors.blue;
      case 'discount':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }
} 