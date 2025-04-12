import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({Key? key}) : super(key: key);

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  String _selectedFilter = 'All';
  final List<String> _statusFilters = ['All', 'Pending', 'Preparing', 'On Delivery', 'Delivered', 'Cancelled'];
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
      // First, get the order document to check its structure and get userId
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }
      
      final orderData = orderDoc.data() as Map<String, dynamic>;
      
      // Update the main order status in orders collection
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});
      
      // If the order has a userId, update the order in the user's orders collection
      if (orderData.containsKey('userId') && orderData['userId'] != null) {
        final userId = orderData['userId'];
        
        // Update the order in user's userOrders subcollection
        try {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(userId)
              .collection('userOrders')
              .doc(orderId)
              .update({'status': newStatus});
          
          print('Updated status in user orders: $userId, orderId: $orderId');
        } catch (e) {
          print('Error updating user order status: $e');
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status: $e')),
      );
    }
  }

  Future<void> _updateTrackingNumber(String orderId, String currentTracking) async {
    TextEditingController trackingController = TextEditingController(text: currentTracking);
    
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Tracking Number'),
          content: TextField(
            controller: trackingController,
            decoration: const InputDecoration(
              hintText: 'Enter tracking number',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Get the order document first to check its structure
                  final orderDoc = await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .get();
                  
                  if (!orderDoc.exists) {
                    throw Exception('Order not found');
                  }
                  
                  final orderData = orderDoc.data() as Map<String, dynamic>;
                  
                  // Update the tracking number in the main order
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .update({'trackingNumber': trackingController.text});
                  
                  // If the order has a userId, update the tracking number in the user's orders collection
                  if (orderData.containsKey('userId') && orderData['userId'] != null) {
                    final userId = orderData['userId'];
                    
                    // Update in userOrders subcollection
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
              child: const Text('UPDATE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Management',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by order ID or customer',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedFilter,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFilter = newValue;
                      });
                    }
                  },
                  items: _statusFilters
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedFilter == 'All'
                  ? FirebaseFirestore.instance.collection('orders').orderBy('timestamp', descending: true).snapshots()
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
                
                // Apply search filter if search query exists
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
                    final totalAmount = data['totalAmount'] ?? 0.0;
                    final status = data['status'] ?? 'Pending';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final dateTime = timestamp != null 
                        ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
                        : 'Unknown date';
                    final trackingNumber = data['trackingNumber'] ?? '';
                    final items = data['items'] as List<dynamic>? ?? [];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          'Order #${orderId.substring(0, min(orderId.length, 8))}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: $dateTime'),
                            Text('Status: $status', 
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(status),
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '₺${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                                _buildCustomerInfo(data),
                                const SizedBox(height: 16),
                                const Text(
                                  'Change Order Status:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                // Modified this part to use SingleChildScrollView for horizontal scrolling
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
    final customerName = data['customerName'] ?? 'N/A';
    final customerEmail = data['customerEmail'] ?? 'N/A';
    final shippingAddress = data['shippingAddress'] ?? 'No address provided';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Information:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        if (customerName != 'N/A') Text('Name: $customerName'),
        if (customerEmail != 'N/A') Text('Email: $customerEmail'),
        const SizedBox(height: 8),
        const Text(
          'Shipping Address:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(shippingAddress),
      ],
    );
  }

  Widget _buildStatusButton(String orderId, String buttonStatus, String currentStatus) {
    final isActive = currentStatus == buttonStatus;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? _getStatusColor(buttonStatus) : Colors.grey.shade200,
        foregroundColor: isActive ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: isActive ? null : () => _updateOrderStatus(orderId, buttonStatus),
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
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  int min(int a, int b) {
    return a < b ? a : b;
  }
}