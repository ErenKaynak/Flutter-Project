import 'package:engineering_project/pages/cart_page.dart';
import 'package:engineering_project/pages/checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:engineering_project/assets/components/cart_manager.dart'
    hide CartItem;
import 'package:engineering_project/pages/product-detail-page.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';

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

  // Status constants
  static const String STATUS_ALL = 'All';
  static const String STATUS_PENDING = 'Pending';
  static const String STATUS_PREPARING = 'Preparing';
  static const String STATUS_ON_DELIVERY = 'On Delivery';
  static const String STATUS_DELIVERED = 'Delivered';
  static const String STATUS_CANCELLED = 'Cancelled';

  // Define standard status values to match admin page
  List<String> _standardStatuses(AppLocalizations l10n) => [
    STATUS_ALL,
    STATUS_PENDING,
    STATUS_PREPARING,
    STATUS_ON_DELIVERY,
    STATUS_DELIVERED,
    STATUS_CANCELLED,
  ];

  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status) {
      case STATUS_ALL:
        return l10n.allOrders;
      case STATUS_PENDING:
        return l10n.pending;
      case STATUS_PREPARING:
        return l10n.preparing;
      case STATUS_ON_DELIVERY:
        return l10n.onDelivery;
      case STATUS_DELIVERED:
        return l10n.delivered;
      case STATUS_CANCELLED:
        return l10n.cancelled;
      default:
        return status;
    }
  }

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
          _errorMessage = AppLocalizations.of(context)!.pleaseSignIn;
          _isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> loadedOrders = [];

      // First check orders/{userId}/userOrders (newer structure from cart_page.dart)
      try {
        final userOrdersSnapshot =
            await FirebaseFirestore.instance
                .collection('orders')
                .doc(user.uid)
                .collection('userOrders')
                .orderBy('orderDate', descending: true)
                .get();

        print(
          'Found ${userOrdersSnapshot.docs.length} orders in userOrders collection',
        );

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
        final orderDocs =
            await FirebaseFirestore.instance
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
              final itemsSnapshot =
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(doc.id)
                      .collection('items')
                      .get();

              items = itemsSnapshot.docs.map((itemDoc) {
                final itemData = itemDoc.data();
                final l10n = AppLocalizations.of(context)!;
                return {
                  'id': itemDoc.id,
                  'name': itemData['name'] ?? l10n.productNotFound,
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
          _errorMessage = AppLocalizations.of(context)!.noOrdersYet;
        }
      });

      print('Total orders loaded: ${loadedOrders.length}');
    } catch (error) {
      print('Error fetching orders: $error');
      setState(() {
        _errorMessage = "${AppLocalizations.of(context)!.somethingWentWrong}: $error";
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
      return _orders
          .where((order) => order["status"].toString() == _filterStatus)
          .toList();
    }
  }

  void _filterByStatus(String status) {
    setState(() {
      _filterStatus = status;
    });
  }

  Future<bool> _hasUserReviewedProduct(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final comments =
        await FirebaseFirestore.instance
            .collection('comments')
            .doc(productId)
            .collection('userComments')
            .where('userId', isEqualTo: user.uid)
            .get();

    return comments.docs.isNotEmpty;
  }

  Future<void> _showRatingDialog(String productId, String productName) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Check if user has already reviewed
    final hasReviewed = await _hasUserReviewedProduct(productId);
    if (hasReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.alreadyReviewed),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int selectedRating = 0;
    String comment = '';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    return showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
          title: Text(l10n.rateProduct),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: themeNotifier.isSpecialModeActive
                          ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade400
                          : Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedRating = index + 1;
                      });
                    },
                    splashRadius: 24,
                    tooltip: '${index + 1} stars',
                  );
                }),
              ),
              Text(
                _getRatingText(selectedRating),
                style: TextStyle(
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.writeReview,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                ),
                onChanged: (value) => comment = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null
                  : () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('comments')
                              .doc(productId)
                              .collection('userComments')
                              .add({
                                'userId': user.uid,
                                'userName': user.displayName ?? 'User',
                                'rating': selectedRating,
                                'comment': comment,
                                'timestamp': FieldValue.serverTimestamp(),
                              });

                          final commentsRef = FirebaseFirestore.instance
                              .collection('comments')
                              .doc(productId)
                              .collection('userComments');

                          final commentsSnapshot = await commentsRef.get();
                          final ratings = commentsSnapshot.docs
                              .map((doc) => doc.data()['rating'] as int)
                              .where((r) => r > 0)
                              .toList();

                          if (ratings.isNotEmpty) {
                            final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
                            await FirebaseFirestore.instance
                                .collection('products')
                                .doc(productId)
                                .update({
                                  'averageRating': double.parse(avgRating.toStringAsFixed(1)),
                                  'ratingCount': ratings.length,
                                });
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.thankYouForReview),
                            ),
                          );
                        } catch (e) {
                          print('Error submitting review: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.failedToSubmitReview),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeNotifier.isSpecialModeActive
                    ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade400
                    : Colors.amber,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text(l10n.submitReview),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    final l10n = AppLocalizations.of(context)!;
    switch (rating) {
      case 0:
        return l10n.selectRating;
      case 1:
        return l10n.poor;
      case 2:
        return l10n.fair;
      case 3:
        return l10n.good;
      case 4:
        return l10n.veryGood;
      case 5:
        return l10n.excellent;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          l10n.orderHistory,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: isDark ? 0 : 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).iconTheme.color),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: themeNotifier.isSpecialModeActive
                    ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade400
                    : Theme.of(context).primaryColor,
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
                              Container(
                                padding: EdgeInsets.all(16.0),
                                margin: EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            themeNotifier.isSpecialModeActive
                                                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade900
                                                : Colors.red.shade900,
                                            Colors.grey.shade900,
                                          ]
                                        : [
                                            themeNotifier.isSpecialModeActive
                                                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade300
                                                : Colors.red.shade300,
                                            Colors.white,
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isDark
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: themeNotifier.isSpecialModeActive
                                                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade200.withOpacity(0.5)
                                                : Colors.black12,
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
                                        color: themeNotifier.isSpecialModeActive
                                            ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade300
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.yourOrders,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isDark ? Colors.grey[400] : Colors.black54,
                                            ),
                                          ),
                                          Text(
                                            l10n.ordersCount(
                                              _orders.length,
                                            ),
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.filterByStatus,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.titleLarge?.color,
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: themeNotifier.isSpecialModeActive
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade400
                : (isDark ? Colors.red.shade400 : Colors.red),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? l10n.somethingWentWrong,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeNotifier.isSpecialModeActive
                  ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                  : Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: themeNotifier.isSpecialModeActive
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade400
                : (isDark ? Colors.red.shade400 : Colors.red),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noOrdersYet,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.yourOrderHistoryWillAppearHere,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeNotifier.isSpecialModeActive
                  ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                  : Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.startShopping),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;
    final statuses = _standardStatuses(l10n);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((status) {
          final isSelected = _filterStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  _filterStatus = selected ? status : l10n.allOrders;
                });
              },
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: themeNotifier.isSpecialModeActive
                  ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade100
                  : Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: themeNotifier.isSpecialModeActive
                  ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                  : Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? (themeNotifier.isSpecialModeActive
                        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                        : Theme.of(context).primaryColor)
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersList() {
    final l10n = AppLocalizations.of(context)!;
    
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
                  l10n.noOrdersWithStatus(_getLocalizedStatus(_filterStatus, l10n)),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tryDifferentFilter,
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
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: isDark ? 1 : 2,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:
              isDark
                  ? BorderSide(color: Colors.grey.shade800)
                  : BorderSide.none,
        ),
        child: ExpansionTile(
          maintainState: false,
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            '${l10n.orderPrefix}${order['orderNumber']}',
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
                DateFormat(
                  l10n.dateFormat,
                  Localizations.localeOf(context).languageCode,
                ).format((order['timestamp'] as Timestamp).toDate()),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusBadge(order['status']),
                  const Spacer(),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${l10n.total}: '),
                        TextSpan(
                          text: '₺${order['total'].toString()}',
                          style: const TextStyle(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
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
                  Text(
                    l10n.items,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...order['items']
                      .map<Widget>(
                        (item) =>
                            _buildOrderItem(item, status: order['status']),
                      )
                      .toList(),
                  const Divider(height: 32),
                  if (order['trackingNumber'] != null &&
                      order['trackingNumber'].isNotEmpty) ...[
                    Text(
                      l10n.trackingNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order['trackingNumber'],
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    l10n.shippingAddressLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order['shippingAddress'] ?? l10n.defaultShippingAddress,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.paymentMethodLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _capitalizeFirstLetter(
                      order['paymentMethod'] ?? l10n.cardPayment,
                    ),
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
                        label: Text(l10n.reorderButton),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                      if (order['status'] == 'Pending')
                        OutlinedButton.icon(
                          onPressed: () {
                            _handleCancelOrder(order);
                          },
                          icon: const Icon(Icons.cancel_outlined),
                          label: Text(l10n.cancelOrder),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
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
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    IconData iconData;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    switch (status) {
      case STATUS_PENDING:
        badgeColor = themeNotifier.isSpecialModeActive
            ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade400
            : Colors.orange;
        iconData = Icons.hourglass_bottom;
        break;
      case STATUS_PREPARING:
        badgeColor = Colors.blue;
        iconData = Icons.restaurant;
        break;
      case STATUS_ON_DELIVERY:
        badgeColor = Colors.purple;
        iconData = Icons.local_shipping;
        break;
      case STATUS_DELIVERED:
        badgeColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case STATUS_CANCELLED:
        badgeColor = Colors.red;
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
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 16, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            _getLocalizedStatus(status, l10n),
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item, {required String status}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item['imagePath'] ?? 'lib/assets/Images/placeholder.png',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? l10n.productNotFound,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${l10n.quantityPrefix} '),
                      TextSpan(text: '${item['quantity']} × ₺${item['price']}'),
                    ],
                  ),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${l10n.itemTotalPrefix} '),
                      TextSpan(
                        text: '₺${(double.parse(item['price'].toString()) * (item['quantity'] as int)).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          if (status == STATUS_DELIVERED)
            FutureBuilder<bool>(
              future: _hasUserReviewedProduct(item['id']),
              builder: (context, snapshot) {
                final bool hasReviewed = snapshot.data ?? false;
                return TextButton(
                  onPressed: hasReviewed ? null : () => _showRatingDialog(item['id'], item['name']),
                  child: Text(
                    hasReviewed ? l10n.alreadyReviewed : l10n.rateProduct,
                    style: TextStyle(
                      color: hasReviewed
                          ? Colors.grey
                          : (themeNotifier.isSpecialModeActive
                              ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                              : Theme.of(context).primaryColor),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _handleReorder(Map<String, dynamic> order) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final List<String> outOfStockItems = [];
      final List<String> insufficientStockItems = [];

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
          insufficientStockItems.add(
            '${item['name']} (Available: $currentStock, Requested: $requestedQuantity)',
          );
        }
      }

      if (outOfStockItems.isNotEmpty || insufficientStockItems.isNotEmpty) {
        String errorMessage = '';

        if (outOfStockItems.isNotEmpty) {
          errorMessage += l10n.outOfStockItems(outOfStockItems.join('\n• ')) + '\n\n';
        }

        if (insufficientStockItems.isNotEmpty) {
          errorMessage += l10n.insufficientStockItems(insufficientStockItems.join('\n• '));
        }

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.cannotReorder),
            content: SingleChildScrollView(child: Text(errorMessage)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
        return;
      }

      final List<CartItem> items = (order['items'] as List)
          .map(
            (item) => CartItem(
              id: item['id'] ?? '',
              name: item['name'] ?? '',
              price: (double.tryParse(item['price']?.toString() ?? '0') ?? 0.0).toString(),
              image: item['imagePath'] ?? item['image'] ?? '',
              quantity: item['quantity'] ?? 1,
            ),
          )
          .toList();

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
          content: Text(l10n.errorCheckingAvailability),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCancelOrder(Map<String, dynamic> order) async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelOrder),
        content: Text(l10n.confirmCancelOrder),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(order['id'])
            .update({'status': STATUS_CANCELLED});
        await _fetchOrders();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToCancelOrder(error.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
