import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the possible states of an order
enum OrderStatus {
  pending,
  preparing,
  onDelivery,
  delivered,
  refundRequested,
  refundInReview,
  refundApproved,
  refundDeclined,
  refunded,
  cancelled;

  /// Gets the display name for the order status
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.onDelivery:
        return 'On Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.refundRequested:
        return 'Refund Requested';
      case OrderStatus.refundInReview:
        return 'Refund In Review';
      case OrderStatus.refundApproved:
        return 'Refund Approved';
      case OrderStatus.refundDeclined:
        return 'Refund Declined';
      case OrderStatus.refunded:
        return 'Refunded';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Represents an order in the system
class Order {
  final String id;
  final DateTime date;
  final OrderStatus status;
  final double total;
  final List<OrderItem> items;
  final String? trackingNumber;

  const Order({
    required this.id,
    required this.date,
    required this.status,
    required this.total,
    required this.items,
    this.trackingNumber,
  });

  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Order(
      id: doc.id,
      date: (data['createdAt'] as Timestamp).toDate(),
      status: _parseOrderStatus(data['status'] as String? ?? 'pending'),
      total: (data['total'] as num).toDouble(),
      trackingNumber: data['trackingNumber'] as String?,
      items: (data['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static OrderStatus _parseOrderStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'preparing':
        return OrderStatus.preparing;
      case 'on delivery':
        return OrderStatus.onDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'refund requested':
        return OrderStatus.refundRequested;
      case 'refund in review':
        return OrderStatus.refundInReview;
      case 'refund approved':
        return OrderStatus.refundApproved;
      case 'refund declined':
        return OrderStatus.refundDeclined;
      case 'refunded':
        return OrderStatus.refunded;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

/// Represents an item within an order
class OrderItem {
  final String name;
  final int quantity;
  final String? imagePath;

  const OrderItem({
    required this.name,
    required this.quantity,
    this.imagePath,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      imagePath: map['imagePath'] as String?,
    );
  }
} 