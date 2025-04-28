import 'package:engineering_project/pages/cart_page.dart';
import 'package:engineering_project/pages/checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:engineering_project/assets/components/cart_manager.dart' hide CartItem;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Order History',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: isDark ? 0 : 2,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : _errorMessage != null && _orders.isEmpty
              ? _buildErrorView()
              : _orders.isEmpty
                  ? _buildEmptyOrdersView()
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              // Header Section matching HomePage style
                              Container(
                                padding: EdgeInsets.all(16.0),
                                margin: EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [Colors.red.shade900, Colors.grey.shade900]
                                        : [Colors.red.shade300, Colors.white],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isDark
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 5,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.red.shade900
                                            : Colors.red.shade300,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 30,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Your Orders",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.black54,
                                            ),
                                          ),
                                          Text(
                                            "${_orders.length} orders",
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Filter Section
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Filter by Status",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.color,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    _buildFilterButtons(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Orders List
                        SliverPadding(
                          padding: EdgeInsets.all(10),
                          sliver: _buildOrdersList(),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildErrorView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, 
            size: 80, 
            color: isDark ? Colors.red.shade400 : Colors.red
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? "Something went wrong",
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
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
          Icon(
            Icons.shopping_bag_outlined, 
            size: 80, 
            color: Theme.of(context).textTheme.bodyMedium?.color
          ),
          const SizedBox(height: 16),
          Text(
            "No orders yet",
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your order history will appear here",
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
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

  Widget _buildFilterButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _standardStatuses.map((status) {
          final isSelected = _filterStatus == status;
          return Padding(
            padding: EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _filterByStatus(status),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? Border.all(
                              color: isDark
                                  ? Colors.red.shade700
                                  : Colors.red.shade400,
                              width: 2,
                            )
                          : null,
                      boxShadow: isSelected && !isDark
                          ? [
                              BoxShadow(
                                color: Colors.red.shade200.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
        addAutomaticKeepAlives: false, // Add this line
        addRepaintBoundaries: true,    // Add this line
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: isDark ? 1 : 2,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDark 
              ? BorderSide(color: Colors.grey.shade800)
              : BorderSide.none,
        ),
        child: ExpansionTile(
          maintainState: false,
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            'Order #${order['orderNumber']}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM dd, yyyy - HH:mm').format(
                  (order['timestamp'] as Timestamp).toDate(),
                ),
                style: const TextStyle(fontSize: 12),
              ),
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
                  ...order['items'].map<Widget>((item) => _buildOrderItem(item)).toList(),
                  const Divider(height: 32),
                  if (order['trackingNumber'] != null && order['trackingNumber'].isNotEmpty) ...[
                    const Text(
                      'Tracking Number:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order['trackingNumber'],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Map<String, dynamic> itemData = item is Map ? item as Map<String, dynamic> : {};
    final String imagePath = itemData["imagePath"] ?? itemData["image"] ?? 'lib/assets/Images/placeholder.png';
    final String itemPrice = itemData["price"]?.toString() ?? '0';
    final int itemQuantity = itemData["quantity"] is int ? itemData["quantity"] : 1;
    final String itemName = itemData["name"] ?? 'Unknown Product';
    
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
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
        cacheWidth: 120,  // Add this line
        cacheHeight: 120, // Add this line
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        cacheWidth: 120,  // Add this line
        cacheHeight: 120, // Add this line
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
  
  void _handleReorder(Map<String, dynamic> order) async {
    try {
      // First check stock levels for all items
      final List<String> outOfStockItems = [];
      final List<String> insufficientStockItems = [];
      
      // Check each item's current stock
      for (var item in order['items']) {
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(item['id'])
            .get();
        
        if (!productDoc.exists) {
          outOfStockItems.add(item['name']);
          continue;
        }

        final currentStock = productDoc.data()?['stock'] ?? 0;
        final requestedQuantity = item['quantity'] ?? 0;

        if (currentStock <= 0) {
          outOfStockItems.add(item['name']);
        } else if (currentStock < requestedQuantity) {
          insufficientStockItems.add('${item['name']} (Available: $currentStock, Requested: $requestedQuantity)');
        }
      }

      // Show error if any items are out of stock or have insufficient stock
      if (outOfStockItems.isNotEmpty || insufficientStockItems.isNotEmpty) {
        String errorMessage = '';
        
        if (outOfStockItems.isNotEmpty) {
          errorMessage += 'The following items are out of stock:\n• ${outOfStockItems.join('\n• ')}\n\n';
        }
        
        if (insufficientStockItems.isNotEmpty) {
          errorMessage += 'Insufficient stock for:\n• ${insufficientStockItems.join('\n• ')}';
        }

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Cannot Reorder'),
            content: SingleChildScrollView(
              child: Text(errorMessage),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // If all stock checks pass, convert order items to CartItem objects
      final List<CartItem> items = (order['items'] as List).map((item) => CartItem(
        id: item['id'] ?? '',
        name: item['name'] ?? '',
        price: (double.tryParse(item['price']?.toString() ?? '0') ?? 0.0).toString(),
        image: item['imagePath'] ?? item['image'] ?? '',
        quantity: item['quantity'] ?? 1,
      )).toList();

      // Navigate to checkout page with the items
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutPage(
            subtotal: (order['total'] ?? 0.0).toDouble(),
            items: items,
            appliedDiscount: null,
          ),
        ),
      );
    } catch (e) {
      print('Error handling reorder: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking product availability. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleCancelOrder(Map<String, dynamic> order) async {
    // Store the context and theme information before showing dialog
    final currentContext = context;
    final isDark = Theme.of(currentContext).brightness == Brightness.dark;
    final dialogBackgroundColor = Theme.of(currentContext).dialogBackgroundColor;
    final titleTextColor = Theme.of(currentContext).textTheme.titleLarge?.color;
    final bodyTextColor = Theme.of(currentContext).textTheme.bodyLarge?.color;
    final primaryColor = Theme.of(currentContext).primaryColor;

    if (!mounted) return;

    final bool? shouldCancel = await showDialog<bool>(
      context: currentContext,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: dialogBackgroundColor,
        title: Text(
          'Cancel Order',
          style: TextStyle(color: titleTextColor),
        ),
        content: Text(
          'Are you sure you want to cancel this order?',
          style: TextStyle(color: bodyTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('NO', style: TextStyle(color: primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YES', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldCancel != true || !mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Update order status in main orders collection
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order['id'])
          .update({
            'status': 'Cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
          });

      // Update order status in user's orders subcollection
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(user.uid)
          .collection('userOrders')
          .doc(order['id'])
          .update({
            'status': 'Cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      // Refresh orders list
      _fetchOrders();

      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error cancelling order: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}