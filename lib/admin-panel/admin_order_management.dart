import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({Key? key}) : super(key: key);

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  String _selectedFilter = 'All';
  final List<String> _statusFilters = ['All', 'Pending', 'Preparing', 'On Delivery', 'Delivered', 'Refunds', 'Cancelled'];
  final List<String> _refundStatuses = [
    'Refund Requested',
    'Refund In Review',
    'Refund Approved',
    'Refund Declined',
    'Refunded',
  ];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      print('Starting order status update for order: $orderId, new status: $newStatus');
      
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }
      
      final orderData = orderDoc.data() as Map<String, dynamic>;
      print('Order data: $orderData');
      
      // --- REFUND LOGIC ---
      if ((newStatus == 'Refund Approved' || newStatus == 'Refunded') && 
          orderData.containsKey('userId') && 
          orderData['userId'] != null) {
        print('Processing refund for order: $orderId');
        final userId = orderData['userId'];
        double totalAmount = (orderData['totalAmount'] ?? orderData['total'] ?? 0.0).toDouble();
        double shippingCost = (orderData['shippingCost'] ?? 0.0).toDouble();
        final double refundAmount = totalAmount - shippingCost;
        final List<dynamic> items = orderData['items'] ?? [];
        
        print('Refund details:');
        print('User ID: $userId');
        print('Refund Amount: $refundAmount');
        print('Items: $items');
        
        final batch = FirebaseFirestore.instance.batch();

        // --- Cashback reversal logic ---
        double cashbackToReverse = 0.0;
        try {
          final txQuery = await FirebaseFirestore.instance
              .collection('wallet_transactions')
              .where('user_id', isEqualTo: userId)
              .where('order_id', isEqualTo: orderId)
              .where('type', isEqualTo: 'purchase')
              .limit(1)
              .get();
          if (txQuery.docs.isNotEmpty) {
            final txData = txQuery.docs.first.data();
            cashbackToReverse = (txData['cashback'] ?? 0.0).toDouble();
            print('Found cashback to reverse: $cashbackToReverse');
          }
        } catch (e) {
          print('Error finding cashback for reversal: $e');
        }
        // --- End cashback reversal logic ---

        // Refund to wallet
        final walletRef = FirebaseFirestore.instance.collection('wallets').doc(userId);
        print('Updating wallet for user: $userId');
        
        // First check if wallet exists
        final walletDoc = await walletRef.get();
        if (!walletDoc.exists) {
          print('Creating new wallet for user: $userId');
          batch.set(walletRef, {
            'balance': refundAmount - cashbackToReverse,
            'last_transaction': FieldValue.serverTimestamp(),
            'user_id': userId,
          });
        } else {
          print('Updating existing wallet for user: $userId');
          batch.update(walletRef, {
            'balance': FieldValue.increment(refundAmount - cashbackToReverse),
            'last_transaction': FieldValue.serverTimestamp(),
          });
        }

        // Log wallet transaction (refund)
        final transactionRef = FirebaseFirestore.instance.collection('wallet_transactions').doc();
        print('Creating wallet transaction record');
        batch.set(transactionRef, {
          'user_id': userId,
          'amount': refundAmount,
          'type': 'refund',
          'timestamp': FieldValue.serverTimestamp(),
          'method': 'order_refund',
          'status': 'completed',
          'reference': 'Order #$orderId',
          'order_id': orderId,
          'description': 'Refund for Order #$orderId',
        });

        // Log cashback reversal transaction if needed
        if (cashbackToReverse > 0) {
          final cashbackTxRef = FirebaseFirestore.instance.collection('wallet_transactions').doc();
          batch.set(cashbackTxRef, {
            'user_id': userId,
            'amount': -cashbackToReverse,
            'type': 'cashback_reversal',
            'timestamp': FieldValue.serverTimestamp(),
            'method': 'cashback_reversal',
            'status': 'completed',
            'reference': 'Order #$orderId',
            'order_id': orderId,
            'description': 'Cashback reversal for Order #$orderId',
          });
        }

        // Update product stock
        print('Updating product stock');
        for (final item in items) {
          final productId = item['id'];
          final quantity = item['quantity'] ?? 1;
          if (productId != null && quantity != null) {
            print('Updating stock for product: $productId, quantity: $quantity');
            final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
            batch.update(productRef, {
              'stock': FieldValue.increment(quantity),
            });
          }
        }

        // Update order status
        print('Updating order status');
        final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
        batch.update(orderRef, {'status': newStatus});

        // Update user order status if exists
        print('Updating user order status');
        final userOrderRef = FirebaseFirestore.instance.collection('orders').doc(userId).collection('userOrders').doc(orderId);
        batch.update(userOrderRef, {'status': newStatus});

        print('Committing batch operations');
        await batch.commit();
        print('Batch operations completed successfully');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $newStatus, refund processed.')),
        );
        return;
      }
      // --- END REFUND LOGIC ---
      
      // Update main order first
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});
      
      // Update user's order if userId exists
      if (orderData.containsKey('userId') && orderData['userId'] != null) {
        final userId = orderData['userId'];
        
        try {
          // First, try to get the user's orders collection
          final userOrdersCollection = FirebaseFirestore.instance
              .collection('orders')
              .doc(userId)
              .collection('userOrders');
              
          // Create the user's order document with all necessary data
          await userOrdersCollection.doc(orderId).set({
            'status': newStatus,
            'orderId': orderId,
            'timestamp': orderData['timestamp'],
            'totalAmount': orderData['totalAmount'] ?? orderData['total'],
            'items': orderData['items'],
            'customerName': orderData['customerName'],
            'customerEmail': orderData['customerEmail'],
            'customerPhone': orderData['customerPhone'],
            'shippingAddress': orderData['shippingAddress'],
            'trackingNumber': orderData['trackingNumber'],
          }, SetOptions(merge: true));
          
          print('Successfully updated user order: $userId, orderId: $orderId');
        } catch (e) {
          print('Error updating user order: $e');
          // Continue even if user order update fails
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
    } catch (e) {
      print('Error in _updateOrderStatus: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status: $e')),
      );
    }
  }

  void _updateTrackingNumber(String orderId, String currentTracking) {
    TextEditingController trackingController = TextEditingController(text: currentTracking);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: Text(
            'Update Tracking Number',
            style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
          ),
          content: TextField(
            controller: trackingController,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: 'Enter tracking number',
              hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final orderDoc = await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .get();
                  
                  if (!orderDoc.exists) {
                    throw Exception('Order not found');
                  }
                  
                  final orderData = orderDoc.data() as Map<String, dynamic>;
                  
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .update({'trackingNumber': trackingController.text});
                  
                  if (orderData.containsKey('userId') && orderData['userId'] != null) {
                    final userId = orderData['userId'];
                    
                    try {
                      await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(userId)
                          .collection('userOrders')
                          .doc(orderId)
                          .update({'trackingNumber': trackingController.text});
                      
                      print('Updated tracking in user orders: $userId, orderId: $orderId');
                    } catch (e) {
                      print('Error updating user order tracking: $e');
                    }
                  }
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tracking number updated')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update tracking number: $e')),
                  );
                }
              },
              child: Text(
                'UPDATE',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportOrdersToCSV() async {
    try {
      setState(() => _isLoading = true);

      // Get all orders first
      final QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('timestamp', descending: true)
          .get();

      // Create CSV data
      List<List<dynamic>> rows = [
        // Header row
        [
          'Order ID',
          'Date',
          'Customer Name',
          'Email',
          'Phone',
          'Status',
          'Total Amount',
          'Tracking Number',
          'Items',
          'Address'
        ]
      ];

      // Add order data
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['timestamp'] as Timestamp?;
        final dateTime = timestamp != null 
            ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
            : 'Unknown';

        rows.add([
          doc.id,
          dateTime,
          data['customerName'] ?? 'N/A',
          data['customerEmail'] ?? 'N/A',
          data['customerPhone'] ?? 'N/A',
          data['status'] ?? 'Pending',
          '₺${(data['totalAmount'] ?? data['total'] ?? 0.0).toStringAsFixed(2)}',
          data['trackingNumber'] ?? 'Not provided',
          (data['items'] as List<dynamic>?)?.map((item) =>
              '${item['quantity']}x ${item['name']}').join('; ') ?? '',
          data['shippingAddress'] ?? 'No address'
        ]);
      }

      // Convert to CSV
      final csv = const ListToCsvConverter().convert(rows);
      
      try {
        // Try to use downloads directory first
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'orders_${DateTime.now().millisecondsSinceEpoch}.csv';
        final file = File('${dir.path}/$fileName');
        
        // Write CSV file
        await file.writeAsString(csv);

        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Orders Export',
          text: 'Orders export from ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orders exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error sharing file: $e');
        throw Exception('Failed to share file');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error exporting orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processRefund(String orderId, Map<String, dynamic> orderData) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Process Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to process the refund for this order?'),
            const SizedBox(height: 16),
            Text(
              'Order Total: ₺${(orderData['totalAmount'] ?? orderData['total'] ?? 0.0).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Customer: ${orderData['customerName'] ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Email: ${orderData['customerEmail'] ?? 'N/A'}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('PROCESS REFUND'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Update order status to Refunded
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({'status': 'Refunded'});

        // If the order has a userId, update the user's order as well
        if (orderData.containsKey('userId') && orderData['userId'] != null) {
          final userId = orderData['userId'];
          try {
            await FirebaseFirestore.instance
                .collection('orders')
                .doc(userId)
                .collection('userOrders')
                .doc(orderId)
                .update({'status': 'Refunded'});
          } catch (e) {
            print('Error updating user order status: $e');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund processed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process refund: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'Order Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: isDark ? 0 : 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _exportOrdersToCSV,
            tooltip: 'Export to CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section with Stats
          Container(
            padding: EdgeInsets.all(16.0),
            margin: EdgeInsets.all(16.0),
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
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.red.shade900 : Colors.red.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_shipping_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                        builder: (context, snapshot) {
                          final orderCount = snapshot.data?.docs.length ?? 0;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Orders Overview",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.grey[400] : Colors.black54,
                                ),
                              ),
                              Text(
                                "$orderCount Orders",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return _buildStatItem(
                              icon: Icons.pending_actions,
                              count: 0,
                              label: 'Pending Orders',
                              color: Colors.orange,
                            );

                            final pendingCount = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data['status'] == 'Pending';
                            }).length;

                            return _buildStatItem(
                              icon: Icons.pending_actions,
                              count: pendingCount,
                              label: 'Pending Orders',
                              color: Colors.orange,
                            );
                          },
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return _buildStatItem(
                              icon: Icons.cancel_outlined,
                              count: 0,
                              label: 'Cancelled Orders',
                              color: Colors.red,
                            );

                            final cancelledCount = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data['status'] == 'Cancelled';
                            }).length;

                            return _buildStatItem(
                              icon: Icons.cancel_outlined,
                              count: cancelledCount,
                              label: 'Cancelled Orders',
                              color: Colors.red,
                            );
                          },
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return _buildStatItem(
                              icon: Icons.money_off,
                              count: 0,
                              label: 'Refund Requests',
                              color: Colors.orange,
                            );

                            final refundRequestCount = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data['status'] == 'Refund Requested';
                            }).length;

                            return _buildStatItem(
                              icon: Icons.money_off,
                              count: refundRequestCount,
                              label: 'Refund Requests',
                              color: Colors.orange,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Search orders...',
                      hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status Filter Section
          Container(
            height: 60,
            margin: EdgeInsets.symmetric(vertical: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final status = _statusFilters[index];
                final isSelected = _selectedFilter == status;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(status),
                    onSelected: (selected) {
                      setState(() => _selectedFilter = selected ? status : "All");
                    },
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Orders List (existing StreamBuilder)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedFilter == 'All'
                  ? FirebaseFirestore.instance.collection('orders').orderBy('timestamp', descending: true).snapshots()
                  : _selectedFilter == 'Refunds'
                      ? FirebaseFirestore.instance
                          .collection('orders')
                          .where('status', whereIn: _refundStatuses)
                          .orderBy('timestamp', descending: true)
                          .snapshots()
                      : FirebaseFirestore.instance
                          .collection('orders')
                          .where('status', isEqualTo: _selectedFilter)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No orders found'));
                }

                var filteredDocs = snapshot.data!.docs;
                
                if (_searchQuery.isNotEmpty) {
                  filteredDocs = filteredDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final orderId = doc.id.toLowerCase();
                    final customerName = (data['customerName'] ?? '').toString().toLowerCase();
                    final customerEmail = (data['customerEmail'] ?? '').toString().toLowerCase();
                    
                    return orderId.contains(_searchQuery.toLowerCase()) || 
                           customerName.contains(_searchQuery.toLowerCase()) ||
                           customerEmail.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final orderId = doc.id;
                    final totalAmount = data['totalAmount'] ?? data['total'] ?? 0.0;
                    final status = data['status'] ?? 'Pending';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final dateTime = timestamp != null 
                        ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
                        : 'Unknown date';
                    final trackingNumber = data['trackingNumber'] ?? '';
                    final items = data['items'] as List<dynamic>? ?? [];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: isDark ? 1 : 2,
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isDark
                            ? BorderSide(color: Colors.grey.shade800)
                            : BorderSide.none,
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        ),
                        child: ExpansionTile(
                          title: Text(
                            'Order #${orderId.substring(0, min(orderId.length, 8))}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date: $dateTime',
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                              Text(
                                'Status: $status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '₺${(data['totalAmount'] ?? data['total'] ?? 0.0).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                          children: [
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Items (${items.length}):'),
                                  const SizedBox(height: 8),
                                  ...items.map<Widget>((item) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item['quantity']}x ${item['name']}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text('₺${(double.parse(item['price'].toString()) * (item['quantity'] ?? 1)).toStringAsFixed(2)}'),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Tracking Number:'),
                                      Row(
                                        children: [
                                          Text(
                                            trackingNumber.isEmpty ? 'Not added' : trackingNumber,
                                            style: TextStyle(
                                              fontStyle: trackingNumber.isEmpty ? FontStyle.italic : FontStyle.normal,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 18),
                                            onPressed: () => _updateTrackingNumber(orderId, trackingNumber),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ListTile(
                                    title: Text('Order Summary'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Subtotal: ₺${data['subtotal']?.toStringAsFixed(2) ?? '0.00'}'),
                                        if (data['discountAmount'] != null && data['discountAmount'] > 0)
                                          Text(
                                            'Discount: -₺${data['discountAmount'].toStringAsFixed(2)} ' +
                                            '(${data['discountCode'] ?? ''})',
                                            style: TextStyle(color: Colors.green),
                                          ),
                                        Text('Shipping: ₺${data['shippingCost']?.toStringAsFixed(2) ?? '0.00'}'),
                                        Text(
                                          'Total: ₺${data['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildCustomerInfo(data),
                                  // Show refund info if status is in _refundStatuses
                                  if (_refundStatuses.contains(status)) ...[
                                    const SizedBox(height: 16),
                                    Text('Refund Request Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    const SizedBox(height: 8),
                                    if (data['refundReason'] != null && data['refundReason'].toString().isNotEmpty)
                                      Text('Reason: ${data['refundReason']}', style: TextStyle(fontSize: 15)),
                                    if (data['refundImages'] != null && (data['refundImages'] as List).isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 80,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: (data['refundImages'] as List).length,
                                          itemBuilder: (context, imgIdx) {
                                            final imgUrl = (data['refundImages'] as List)[imgIdx];
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8.0),
                                                child: Image.network(
                                                  imgUrl,
                                                  height: 80,
                                                  width: 80,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      height: 80,
                                                      width: 80,
                                                      color: Colors.grey.shade200,
                                                      child: const Icon(Icons.broken_image),
                                                    );
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Text('Refund Handling:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _buildRefundStatusChip('Refund Requested', status),
                                          const SizedBox(width: 8),
                                          _buildRefundStatusChip('Refund In Review', status),
                                          const SizedBox(width: 8),
                                          _buildRefundStatusChip('Refund Approved', status),
                                          const SizedBox(width: 8),
                                          _buildRefundStatusChip('Refund Declined', status),
                                          const SizedBox(width: 8),
                                          _buildRefundStatusChip('Refunded', status),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Show clickable refund handling buttons for admin
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _buildStatusButton(orderId, 'Refund In Review', status),
                                          const SizedBox(width: 8),
                                          _buildStatusButton(orderId, 'Refund Approved', status),
                                          const SizedBox(width: 8),
                                          _buildStatusButton(orderId, 'Refund Declined', status),
                                          const SizedBox(width: 8),
                                          _buildStatusButton(orderId, 'Refunded', status),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Change Order Status:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: Row(
                                              children: [
                                                _buildStatusButton(orderId, 'Pending', status),
                                                const SizedBox(width: 8),
                                                _buildStatusButton(orderId, 'Preparing', status),
                                                const SizedBox(width: 8),
                                                _buildStatusButton(orderId, 'On Delivery', status),
                                                const SizedBox(width: 8),
                                                _buildStatusButton(orderId, 'Delivered', status),
                                                const SizedBox(width: 8),
                                                _buildStatusButton(orderId, 'Cancelled', status),
                                              ],
                                            ),
                                          ),
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customerName = data['customerName'] ?? 'N/A';
    final customerEmail = data['customerEmail'] ?? 'N/A';
    final customerPhone = data['customerPhone'] ?? 'N/A';
    final shippingAddress = data['shippingAddress'] ?? 'No address provided';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withOpacity(0.3) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          SizedBox(height: 12),
          
          // Customer Details
          Row(
            children: [
              Icon(Icons.person_outline, 
                size: 20,
                color: Theme.of(context).iconTheme.color,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  customerName,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // Email
          Row(
            children: [
              Icon(Icons.email_outlined,
                size: 20,
                color: Theme.of(context).iconTheme.color,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  customerEmail,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // Phone
          Row(
            children: [
              Icon(Icons.phone_outlined,
                size: 20,
                color: Theme.of(context).iconTheme.color,
              ),
              SizedBox(width: 8),
              Text(
                customerPhone,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          
          Divider(height: 24),
          
          // Shipping Address
          Text(
            'Shipping Address',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined,
                size: 20,
                color: Theme.of(context).iconTheme.color,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  shippingAddress,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String orderId, String buttonStatus, String currentStatus) {
    final isActive = currentStatus == buttonStatus;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Don't show refund button if order is not in Refund Requested status
    if (buttonStatus == 'Refunded' && currentStatus != 'Refund Requested') {
      return const SizedBox.shrink();
    }
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? _getStatusColor(buttonStatus)
            : isDark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
        foregroundColor: isActive
            ? Colors.white
            : isDark
                ? Colors.grey.shade300
                : Colors.grey.shade800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: isActive
          ? null
          : () {
              _updateOrderStatus(orderId, buttonStatus);
            },
      child: Text(buttonStatus),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Preparing':
        return Colors.blue;
      case 'On Delivery':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      case 'Refund Requested':
        return Colors.orange;
      case 'Refund In Review':
        return Colors.blue;
      case 'Refund Approved':
        return Colors.green;
      case 'Refund Declined':
        return Colors.red;
      case 'Refunded':
        return Colors.green.shade700;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  int min(int a, int b) {
    return a < b ? a : b;
  }

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label.replaceAll(' Orders', '');
          if (label == 'Refund Requests') {
            _selectedFilter = 'Refund Requested';
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedFilter == label.replaceAll(' Orders', '') || 
                 (label == 'Refund Requests' && _selectedFilter == 'Refund Requested')
              ? color.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundStatusChip(String chipStatus, String currentStatus) {
    final isActive = chipStatus == currentStatus;
    Color color = _getStatusColor(chipStatus);
    return Chip(
      label: Text(
        chipStatus,
        style: TextStyle(
          color: isActive ? Colors.white : color,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: isActive ? color : color.withOpacity(0.15),
      side: isActive ? BorderSide(color: color, width: 2) : null,
    );
  }
}