import 'package:engineering_project/assets/components/discount_code.dart';
import 'package:engineering_project/assets/components/discount_service.dart';
import 'package:engineering_project/pages/home_page.dart';
import 'package:engineering_project/pages/past_orders_page.dart';
import 'package:engineering_project/pages/root_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class CartItem {
  final String id;
  final String name;
  final String price; // Price in TRY
  final String image;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.quantity = 1,
  });

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartItem(
      id: doc.id,
      name: data['name'] ?? 'Unknown Product',
      price: data['price']?.toString() ?? '0',
      image: data['imagePath'] ?? '',
      quantity: data['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imagePath': image,
      'quantity': quantity,
    };
  }
}

class CartManager {
  static final CartManager _instance = CartManager._internal();

  factory CartManager() {
    return _instance;
  }

  CartManager._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _cartUpdateListeners = <Function(List<CartItem>)>[];

  List<CartItem> _cartItems = [];
  List<CartItem> get items => List.unmodifiable(_cartItems);

  StreamSubscription<QuerySnapshot>? _cartSubscription;

  void addListener(Function(List<CartItem>) listener) {
    _cartUpdateListeners.add(listener);
  }

  void removeListener(Function(List<CartItem>) listener) {
    _cartUpdateListeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _cartUpdateListeners) {
      listener(_cartItems);
    }
  }

  Future<void> loadCart() async {
    final user = _auth.currentUser;
    if (user == null) {
      _cartItems = [];
      _notifyListeners();
      return;
    }

    await _cartSubscription?.cancel();

    _cartSubscription = _firestore
        .collection('cart')
        .doc(user.uid)
        .collection('userCart')
        .snapshots()
        .listen(
          (snapshot) {
            _cartItems =
                snapshot.docs
                    .map((doc) => CartItem.fromFirestore(doc))
                    .toList();
            print('Cart loaded: ${_cartItems.length} items');
            _notifyListeners();
          },
          onError: (error) {
            print('Error loading cart: $error');
            _cartItems = [];
            _notifyListeners();
          },
        );
  }

  Future<void> updateQuantity(String id, int change) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore
          .collection('cart')
          .doc(user.uid)
          .collection('userCart')
          .doc(id);

      final doc = await docRef.get();
      if (doc.exists) {
        final currentQuantity = doc.data()?['quantity'] ?? 1;
        final newQuantity = (currentQuantity + change).clamp(1, 10);

        await docRef.update({'quantity': newQuantity});
        print('Updated quantity for $id to $newQuantity');
      }
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  Future<void> removeItem(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('cart')
          .doc(user.uid)
          .collection('userCart')
          .doc(id)
          .delete();
      print('Removed item $id from cart');
    } catch (e) {
      print('Error removing item: $e');
    }
  }

  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final cartRef = _firestore
          .collection('cart')
          .doc(user.uid)
          .collection('userCart');

      final batch = _firestore.batch();
      final docs = await cartRef.get();

      for (var doc in docs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Cart cleared');
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  double get totalPrice {
    return _cartItems.fold(0.0, (sum, item) {
      double itemPrice = double.tryParse(item.price) ?? 0.0;
      return sum + (itemPrice * item.quantity);
    });
  }

  int get itemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  void dispose() {
    _cartSubscription?.cancel();
  }
}

class OrderSuccessPage extends StatelessWidget {
  final double totalAmount;
  final String orderId;

  const OrderSuccessPage({
    Key? key,
    required this.totalAmount,
    required this.orderId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmation'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Payment Successful!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Amount Paid: ₺${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your order has been placed successfully.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Order ID: ${orderId.substring(0, 8)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => OrderHistoryPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'VIEW ORDERS',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => RootScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text(
                    'CONTINUE SHOPPING',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartManager _cartManager = CartManager();
  bool _isProcessingPayment = false;
  bool _isLoading = true;
  String? _loginError;
  final TextEditingController _discountCodeController = TextEditingController();
  final DiscountService _discountService = DiscountService();
  DiscountCode? _appliedDiscount;
  bool _isApplyingDiscount = false;
  String? _discountError;

  Future<void> _applyDiscountCode() async {
    final code = _discountCodeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _discountError = 'Please enter a discount code';
      });
      return;
    }

    setState(() {
      _isApplyingDiscount = true;
      _discountError = null;
    });

    try {
      final discount = await _discountService.validateCode(code);

      if (discount == null) {
        setState(() {
          _discountError = 'Invalid or expired discount code';
        });
        return;
      }

      // Check if applicable to cart items
      if (discount.applicableCategories != null &&
          discount.applicableCategories!.isNotEmpty) {
        // Fetch categories for cart items
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final cartItemsWithCategories = await Future.wait(
          _cartManager.items.map((item) async {
            final productDoc =
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(item.id)
                    .get();
            final category = productDoc.data()?['category'] ?? '';
            return {'item': item, 'category': category};
          }),
        );

        // Check if any item matches the applicable categories
        final hasMatchingCategory = cartItemsWithCategories.any(
          (item) => discount.isApplicableToCategory(item['category'] as String),
        );

        if (!hasMatchingCategory) {
          setState(() {
            _discountError =
                'This code is not applicable to items in your cart';
          });
          return;
        }
      }

      setState(() {
        _appliedDiscount = discount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Discount code applied: ${discount.discountPercentage}% off',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _discountError = 'Error applying discount: $e';
      });
    } finally {
      setState(() {
        _isApplyingDiscount = false;
      });
    }
  }

  void _removeDiscount() {
    setState(() {
      _appliedDiscount = null;
      _discountCodeController.clear();
      _discountError = null;
    });
  }

  // Calculate the discounted total price
  double get _discountedTotal {
    final originalTotal = _cartManager.totalPrice;

    if (_appliedDiscount == null) {
      return originalTotal;
    }

    final discountAmount = _appliedDiscount!.calculateDiscount(originalTotal);
    return originalTotal - discountAmount;
  }

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoadCart();
  }

  Future<void> _checkLoginAndLoadCart() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _loginError = 'Please log in to view your cart';
          _isLoading = false;
        });
        return;
      }

      _cartManager.addListener(_updateCartState);
      await _cartManager.loadCart();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error in cart initialization: $e');
      setState(() {
        _loginError = 'Error loading cart: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cartManager.removeListener(_updateCartState);
    _discountCodeController.dispose(); // Add this line
    super.dispose();
  }

  void _updateCartState(List<CartItem> _) {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _processPayment() async {
    if (_cartManager.items.isEmpty) return;

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final originalAmount = _cartManager.totalPrice;
      final discountAmount =
          _appliedDiscount?.calculateDiscount(originalAmount) ?? 0.0;
      final totalAmount = originalAmount - discountAmount;

      // Create a list of order items for saving to Firestore
      final orderItems =
          _cartManager.items.map((item) => item.toMap()).toList();

      // Get user info (optional)
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      Map<String, dynamic>? userData =
          userDoc.exists ? userDoc.data() as Map<String, dynamic>? : null;

      String shippingAddress =
          userData?['address'] ?? 'Default Shipping Address';

      // Create a batch to handle multiple operations atomically
      final batch = FirebaseFirestore.instance.batch();

      // Update product stock levels
      for (var item in _cartManager.items) {
        final productRef = FirebaseFirestore.instance
            .collection('products')
            .doc(item.id);

        // Get current product data to check stock
        final productDoc = await productRef.get();
        if (productDoc.exists) {
          final productData = productDoc.data();
          if (productData != null) {
            final currentStock = productData['stock'] ?? 0;

            // Ensure we don't go below zero stock
            final newStock =
                (currentStock - item.quantity) < 0
                    ? 0
                    : currentStock - item.quantity;

            // Add stock update to batch
            batch.update(productRef, {'stock': newStock});
          }
        }
      }

      // Apply discount if present
      if (_appliedDiscount != null) {
        await _discountService.applyDiscount(_appliedDiscount!.id);
      }

      // Order data with discount information
      final orderData = {
        'items': orderItems,
        'originalAmount': originalAmount,
        'discountAmount': discountAmount,
        'totalAmount': totalAmount,
        'discountCode': _appliedDiscount?.code,
        'discountPercentage': _appliedDiscount?.discountPercentage,
        'orderDate': FieldValue.serverTimestamp(),
        'status': 'Processing',
        'paymentMethod': 'card',
        'shippingAddress': shippingAddress,
      };

      // Save order to both locations with consistent structure
      // 1. Save in userOrders collection (for user's order history)
      final userOrderRef =
          FirebaseFirestore.instance
              .collection('orders')
              .doc(user.uid)
              .collection('userOrders')
              .doc();

      batch.set(userOrderRef, orderData);

      // 2. Save in orders collection (for admin panel)
      batch.set(
        FirebaseFirestore.instance.collection('orders').doc(userOrderRef.id),
        {
          'userId': user.uid,
          'userEmail': user.email,
          'userName': userData?['name'] ?? user.displayName ?? 'Anonymous User',
          ...orderData,
          'timestamp': FieldValue.serverTimestamp(),
          'trackingNumber': '',
        },
      );

      // Execute all operations as a single atomic batch
      await batch.commit();

      // Clear the cart after successful order
      await _cartManager.clearCart();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => OrderSuccessPage(
                  totalAmount: totalAmount,
                  orderId: userOrderRef.id,
                ),
          ),
        );
      }
    } catch (e) {
      print('Payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          title: Text(
            'Your Cart',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    final cartItems = _cartManager.items;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Your Cart',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).errorColor),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Clear Cart',
                      style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
                    ),
                    content: Text(
                      'Are you sure you want to remove all items?',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _cartManager.clearCart();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'CLEAR',
                          style: TextStyle(color: Theme.of(context).errorColor),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Add items to your cart to checkout',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          color: Theme.of(context).errorColor,
                          child: Icon(
                            Icons.delete,
                            color: Theme.of(context).colorScheme.onError,
                          ),
                        ),
                        onDismissed: (direction) {
                          _cartManager.removeItem(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} removed from cart'),
                              action: SnackBarAction(
                                label: 'UNDO',
                                onPressed: () {
                                  // Undo logic would require re-adding the item
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: (item.image.startsWith('http') ||
                                            item.image.startsWith('https'))
                                        ? Image.network(
                                            item.image,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.image,
                                                color: Theme.of(context).iconTheme.color,
                                              );
                                            },
                                          )
                                        : Image.asset(
                                            item.image,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.image,
                                                color: Theme.of(context).iconTheme.color,
                                              );
                                            },
                                          ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '₺${item.price}',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Container(
                                        padding: EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.secondaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                      onPressed: () => _cartManager.updateQuantity(item.id, -1),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Container(
                                        padding: EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.secondaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                      onPressed: () => _cartManager.updateQuantity(item.id, 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[50],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_appliedDiscount == null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _discountCodeController,
                                decoration: InputDecoration(
                                  labelText: 'Discount Code',
                                  hintText: 'Enter code',
                                  errorText: _discountError,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                    ),
                                  ),
                                  labelStyle: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _isApplyingDiscount ? null : _applyDiscountCode,
                              child: _isApplyingDiscount
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text('APPLY'),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.discount_outlined,
                                color: Colors.green,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Discount applied: ${_appliedDiscount!.code}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      '${_appliedDiscount!.discountPercentage}% off',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _removeDiscount,
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: Offset(0, -2),
                            ),
                          ],
                  ),
                  child: Column(
                    children: [
                      if (_appliedDiscount != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            Text(
                              '₺${_cartManager.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Discount (${_appliedDiscount!.discountPercentage}%)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              '-₺${_appliedDiscount!.calculateDiscount(_cartManager.totalPrice).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 20),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          Text(
                            '₺${_discountedTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: cartItems.isEmpty || _isProcessingPayment ? null : _processPayment,
                          child: _isProcessingPayment
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'CHECKOUT',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

extension on ThemeData {
  get errorColor => null;
}
