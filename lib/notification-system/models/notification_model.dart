import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  general,
  discount,
  order,
  system
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final String? imageUrl;
  final bool isRead;
  final String? discountCode;
  final double? discountPercentage;
  final String? discountId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.imageUrl,
    this.isRead = false,
    this.discountCode,
    this.discountPercentage,
    this.discountId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] as String,
      message: data['message'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => NotificationType.general,
      ),
      imageUrl: data['imageUrl'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      discountCode: data['discountCode'] as String?,
      discountPercentage: (data['discountPercentage'] as num?)?.toDouble(),
      discountId: data['discountId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString(),
      'imageUrl': imageUrl,
      'isRead': isRead,
      'discountCode': discountCode,
      'discountPercentage': discountPercentage,
      'discountId': discountId,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    String? imageUrl,
    bool? isRead,
    String? discountCode,
    double? discountPercentage,
    String? discountId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      discountCode: discountCode ?? this.discountCode,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountId: discountId ?? this.discountId,
    );
  }
} 