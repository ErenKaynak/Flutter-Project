import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({Key? key}) : super(key: key);

  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String _filterStatus = "All";
  String? _errorMessage;

  // Define standard status values to match admin page
  final List<String> _standardStatuses = [
    "All", 
    "Pending", 
    "Preparing", 
    "On Delivery", 
    "Delivered", 
    "Cancelled"
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = "Please login to view your orders";
          _isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> loadedOrders = [];

      // First check orders/{userId}/userOrders (newer structure from cart_page.dart)
      try {
        final userOrdersSnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .doc(user.uid)
            .collection('userOrders')
            .orderBy('orderDate', descending: true)
            .get();

        print('Found ${userOrdersSnapshot.docs.length} orders in userOrders collection');

        for (var doc in userOrdersSnapshot.docs) {
          final data = doc.data();
          
          // Items are stored directly in the order document as an array
          final List<dynamic> itemsData = data['items'] as List<dynamic>? ?? [];
          
          // Ensure we standardize the status to match admin page
          final originalStatus = data['status'] ?? 'Pending';
          final standardizedStatus = _standardizeStatus(originalStatus);
          
          loadedOrders.add({
            'id': doc.id,
            'orderNumber': doc.id.substring(0, 8),
            'timestamp': data['orderDate'] ?? Timestamp.now(),
            'total': data['totalAmount'] ?? 0,
            'status': standardizedStatus,
            'items': itemsData,
            'shippingAddress': data['shippingAddress'] ?? 'No address provided',
            'paymentMethod': data['paymentMethod'] ?? 'Not specified',
            'trackingNumber': data['trackingNumber'] ?? '',
          });
        }
      } catch (e) {
        print('Error fetching from userOrders: $e');
      }

      // Also check the orders collection for this user (older structure)
      try {
        final orderDocs = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .get();

        print('Found ${orderDocs.docs.length} orders in orders collection');

        for (var doc in orderDocs.docs) {
          // Skip orders we already have (could be duplicates between the two structures)
          if (loadedOrders.any((order) => order['id'] == doc.id)) {
            continue;
          }

          final data = doc.data();
          List<dynamic> items = [];
          
          // Check if items are in the document or in a subcollection
          if (data.containsKey('items') && data['items'] is List) {
            items = data['items'] as List<dynamic>;
          } else {
            // Try to fetch items from subcollection
            try {
              final itemsSnapshot = await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(doc.id)
                  .collection('items')
                  .get();
                  
              items = itemsSnapshot.docs.map((itemDoc) {
                final itemData = itemDoc.data();
                return {
                  'id': itemDoc.id,
                  'name': itemData['name'] ?? 'Unknown Product',
                  'price': itemData['price']?.toString() ?? '0',
                  'imagePath': itemData['imagePath'] ?? 'lib/assets/Images/placeholder.png',
                  'quantity': itemData['quantity'] ?? 1,
                };
              }).toList();
            } catch (e) {
              print('Error fetching items subcollection: $e');
            }
          }

          // Ensure we standardize the status to match admin page
          final originalStatus = data['status'] ?? 'Pending';
          final standardizedStatus = _standardizeStatus(originalStatus);

          loadedOrders.add({
            'id': doc.id,
            'orderNumber': data['orderNumber'] ?? doc.id.substring(0, 8),
            'timestamp': data['timestamp'] as Timestamp? ?? Timestamp.now(),
            'total': data['totalAmount'] ?? data['total'] ?? 0,
            'status': standardizedStatus,
            'items': items,
            'shippingAddress': data['shippingAddress'] ?? 'No address provided',
            'paymentMethod': data['paymentMethod'] ?? 'Not specified',
            'trackingNumber': data['trackingNumber'] ?? '',
          });
        }
      } catch (e) {
        print('Error fetching from orders collection: $e');
      }

      setState(() {
        _orders = loadedOrders;
        _isLoading = false;
        if (loadedOrders.isEmpty) {
          _errorMessage = "No orders found";
        }
      });
      
      print('Total orders loaded: ${loadedOrders.length}');
      
    } catch (error) {
      print('Error fetching orders: $error');
      setState(() {
        _errorMessage = "Error loading orders: $error";
        _isLoading = false;
      });
    }
  }

  // Helper method to standardize status values
  String _standardizeStatus(String status) {
    final lowerStatus = status.toLowerCase();
    
    // Map possible status values to standard ones
    if (lowerStatus == 'processing' || lowerStatus == 'pending') {
      return 'Pending';
    } else if (lowerStatus == 'preparing') {
      return 'Preparing';
    } else if (lowerStatus == 'on delivery' || lowerStatus == 'shipped') {
      return 'On Delivery';
    } else if (lowerStatus == 'delivered' || lowerStatus == 'completed') {
      return 'Delivered';
    } else if (lowerStatus == 'cancelled') {
      return 'Cancelled';
    }
    
    // If no match, return with first letter capitalized
    return _capitalizeFirstLetter(status);
  }

  List<Map<String, dynamic>> get filteredOrders {
    if (_filterStatus == "All") {
      return _orders;
    } else {
      return _orders.where((order) => 
        order["status"].toString() == _filterStatus
      ).toList();
    }
  }

  void _filterByStatus(String status) {
    setState(() {
      _filterStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _errorMessage != null && _orders.isEmpty
              ? _buildErrorView()
              : _orders.isEmpty
                  ? _buildEmptyOrdersView()
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOrdersHeader(),
                                const SizedBox(height: 10),
                                _buildFilterButtons(),
                              ],
                            ),
                          ),
                        ),
                        _buildOrdersList(),
                      ],
                    ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? "Something went wrong",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "No orders yet",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Your order history will appear here",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "My Orders",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          "${filteredOrders.length} orders",
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: _standardStatuses.map((status) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _buildStatusFilter(status),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusFilter(String status) {
    bool isSelected = _filterStatus == status;
    
    return InkWell(
      onTap: () => _filterByStatus(status),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (filteredOrders.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Column(
              children: [
                Icon(Icons.filter_list_off, size: 70, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  "No orders with '$_filterStatus' status",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Try selecting a different filter",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final order = filteredOrders[index];
          return _buildOrderCard(order);
        },
        childCount: filteredOrders.length,
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final timestamp = order['timestamp'];
    final date = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();
    final dateFormatted = DateFormat('MMM dd, yyyy - HH:mm').format(date);
    final List<dynamic> items = order['items'] as List<dynamic>;
    final String trackingNumber = order['trackingNumber'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: EdgeInsets.zero,
        title: Text(
          'Order #${order['orderNumber']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(dateFormatted, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusBadge(order['status']),
                const Spacer(),
                Text(
                  'Total: ₺${order['total'].toString()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...items.map<Widget>((item) => _buildOrderItem(item)).toList(),
                const Divider(height: 32),
                if (trackingNumber.isNotEmpty) ...[
                  const Text(
                    'Tracking Number:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trackingNumber,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                ],
                const Text(
                  'Shipping Address:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  order['shippingAddress'] ?? 'No address provided',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Payment Method:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _capitalizeFirstLetter(order['paymentMethod'] ?? 'Not specified'),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        _handleReorder(order);
                      },
                      icon: const Icon(Icons.replay),
                      label: const Text('Reorder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    if (order['status'] == 'Pending')
                      OutlinedButton.icon(
                        onPressed: () {
                          _handleCancelOrder(order);
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

 Widget _buildStatusBadge(String status) {
  Color badgeColor;
  IconData iconData;
  
  switch (status) {
    case 'Pending':
      badgeColor = Colors.orange;  // Changed to match admin
      iconData = Icons.hourglass_bottom;
      break;
    case 'Preparing':
      badgeColor = Colors.blue;  // Changed to match admin
      iconData = Icons.restaurant;
      break;
    case 'On Delivery':
      badgeColor = Colors.purple;  // Already matches admin
      iconData = Icons.local_shipping;
      break;
    case 'Delivered':
      badgeColor = Colors.green;  // Already matches admin
      iconData = Icons.check_circle;
      break;
    case 'Cancelled':
      badgeColor = Colors.red;  // Already matches admin
      iconData = Icons.cancel;
      break;
    default:
      badgeColor = Colors.grey;
      iconData = Icons.help_outline;
  }
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: badgeColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: badgeColor.withOpacity(0.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconData, size: 12, color: badgeColor),
        const SizedBox(width: 4),
        Text(
          status,
          style: TextStyle(
            fontSize: 12,
            color: badgeColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildOrderItem(dynamic item) {
    // Handle both string and map formats for item
    final Map<String, dynamic> itemData = item is Map ? item as Map<String, dynamic> : {};
    
    final String imagePath = itemData["imagePath"] ?? itemData["image"] ?? 'lib/assets/Images/placeholder.png';
    final String itemPrice = itemData["price"]?.toString() ?? '0';
    final int itemQuantity = itemData["quantity"] is int ? itemData["quantity"] : 1;
    final String itemName = itemData["name"] ?? 'Unknown Product';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildProductImage(imagePath),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: $itemQuantity × ₺$itemPrice',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Item Total: ₺${(double.tryParse(itemPrice) ?? 0) * itemQuantity}',
                  style: TextStyle(color: Colors.green[700], fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductImage(String imagePath) {
    if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
      );
    }
  }
  
  Widget _buildFallbackImage() {
    return Center(
      child: Icon(
        Icons.image_not_supported,
        size: 24,
        color: Colors.grey[400],
      ),
    );
  }
  
  void _handleReorder(Map<String, dynamic> order) {
    // Implement reorder functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reorder functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _handleCancelOrder(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order cancellation functionality coming soon'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('YES', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}