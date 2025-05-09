import 'package:engineering_project/assets/components/discount_code.dart';
import 'package:engineering_project/assets/components/discount_service.dart';
import 'package:engineering_project/pages/checkout_page.dart';
import 'package:engineering_project/pages/home_page.dart';
import 'package:engineering_project/pages/past_orders_page.dart';
import 'package:engineering_project/pages/root_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:provider/provider.dart';

class CartItem {
  final String id;
  final String name;
  final String price;
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
            _notifyListeners();
          },
          onError: (error) {
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
      }
    } catch (_) {}
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
    } catch (_) {}
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
    } catch (_) {}
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
    final colorScheme = Theme.of(context).colorScheme;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmation'),
        backgroundColor:
            themeNotifier.isSpecialModeActive
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                : Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: colorScheme.secondary,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Payment Successful!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Amount Paid: ₺${totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your order has been placed successfully.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order ID: ${orderId.substring(0, 8)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                      MaterialPageRoute(builder: (_) => OrderHistoryPage()),
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
                    backgroundColor:
                        themeNotifier.isSpecialModeActive
                            ? themeNotifier.getThemeColor(
                              themeNotifier.specialTheme,
                            )
                            : Colors.red,
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
                      MaterialPageRoute(builder: (_) => RootScreen()),
                      (route) => false,
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

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoadCart();
  }

  Future<void> _checkLoginAndLoadCart() async {
    setState(() => _isLoading = true);

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

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _loginError = 'Error loading cart: $e';
        _isLoading = false;
      });
    }
  }

  void _updateCartState(List<CartItem> _) {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cartManager.removeListener(_updateCartState);
    _discountCodeController.dispose();
    super.dispose();
  }

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

      if (discount.applicableCategories != null &&
          discount.applicableCategories!.isNotEmpty) {
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

  void _proceedToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CheckoutPage(
              subtotal: _cartManager.totalPrice,
              appliedDiscount: _appliedDiscount,
              items: _cartManager.items,
            ),
      ),
    );
  }

  double get _discountedTotal {
    final originalTotal = _cartManager.totalPrice;
    if (_appliedDiscount == null) return originalTotal;
    final discountAmount = _appliedDiscount!.calculateDiscount(originalTotal);
    return originalTotal - discountAmount;
  }

  Future<void> _processPayment() async {
    if (_cartManager.items.isEmpty) return;

    setState(() => _isProcessingPayment = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final originalAmount = _cartManager.totalPrice;
      final discountAmount =
          _appliedDiscount?.calculateDiscount(originalAmount) ?? 0.0;
      final totalAmount = originalAmount - discountAmount;

      final orderItems =
          _cartManager.items.map((item) => item.toMap()).toList();
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final userData =
          userDoc.exists ? userDoc.data() as Map<String, dynamic>? : null;
      final shippingAddress =
          userData?['address'] ?? 'Default Shipping Address';

      final batch = FirebaseFirestore.instance.batch();

      for (var item in _cartManager.items) {
        final productRef = FirebaseFirestore.instance
            .collection('products')
            .doc(item.id);
        final productDoc = await productRef.get();

        if (productDoc.exists) {
          final productData = productDoc.data();
          final currentStock = productData?['stock'] ?? 0;
          final newStock =
              (currentStock - item.quantity) < 0
                  ? 0
                  : currentStock - item.quantity;
          batch.update(productRef, {'stock': newStock});
        }
      }

      if (_appliedDiscount != null) {
        await _discountService.applyDiscount(_appliedDiscount!.id);
      }

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

      final userOrderRef =
          FirebaseFirestore.instance
              .collection('orders')
              .doc(user.uid)
              .collection('userOrders')
              .doc();

      batch.set(userOrderRef, orderData);

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

      await batch.commit();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartItems = _cartManager.items;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor:
              themeNotifier.isSpecialModeActive
                  ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                  : (theme.brightness == Brightness.light
                      ? Colors.red.shade700
                      : Theme.of(context).appBarTheme.backgroundColor),
          title: Text('Your Cart', style: TextStyle(color: Colors.white)),
          leading: BackButton(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loginError != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor:
              themeNotifier.isSpecialModeActive
                  ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                  : (theme.brightness == Brightness.light
                      ? Colors.red.shade700
                      : Theme.of(context).appBarTheme.backgroundColor),
          title: Text('Your Cart', style: TextStyle(color: Colors.white)),
          leading: BackButton(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle,
                size: 80,
                color: theme.iconTheme.color?.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                _loginError!,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      themeNotifier.isSpecialModeActive
                          ? themeNotifier.getThemeColor(
                            themeNotifier.specialTheme,
                          )
                          : Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('GO TO LOGIN'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            themeNotifier.isSpecialModeActive
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                : (theme.brightness == Brightness.light
                    ? Colors.red.shade700
                    : Theme.of(context).appBarTheme.backgroundColor),
        title: Text('Your Cart', style: TextStyle(color: Colors.white)),
        leading: BackButton(color: Colors.white),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text('Clear Cart'),
                        content: const Text(
                          'Are you sure you want to remove all items?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () {
                              _cartManager.clearCart();
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'CLEAR',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
        ],
      ),
      body:
          cartItems.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color:
                          themeNotifier.isSpecialModeActive
                              ? themeNotifier.getThemeColor(
                                themeNotifier.specialTheme,
                              )
                              : Colors.red,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your cart is empty',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Add items to your cart to checkout',
                      style: theme.textTheme.bodySmall,
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
                            padding: const EdgeInsets.only(right: 20),
                            color:
                                themeNotifier.isSpecialModeActive
                                    ? themeNotifier.getThemeColor(
                                      themeNotifier.specialTheme,
                                    )
                                    : Colors.red,
                            child: const Icon(
                              Icons.delete_outline_outlined,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _cartManager.removeItem(item.id),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child:
                                          item.image.startsWith('http')
                                              ? Image.network(
                                                item.image,
                                                fit: BoxFit.cover,
                                              )
                                              : Image.asset(
                                                item.image,
                                                fit: BoxFit.cover,
                                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₺${item.price}',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color:
                                                    themeNotifier
                                                            .isSpecialModeActive
                                                        ? themeNotifier
                                                            .getThemeColor(
                                                              themeNotifier
                                                                  .specialTheme,
                                                            )
                                                        : Colors.red,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.red.shade100,
                                          child: Icon(
                                            item.quantity == 1
                                                ? Icons.delete_outline_outlined
                                                : Icons.remove,
                                            size: 16,
                                            color:
                                                themeNotifier
                                                        .isSpecialModeActive
                                                    ? themeNotifier
                                                        .getThemeColor(
                                                          themeNotifier
                                                              .specialTheme,
                                                        )
                                                    : Colors.red,
                                          ),
                                        ),
                                        onPressed: () {
                                          if (item.quantity == 1) {
                                            _cartManager.removeItem(item.id);
                                          } else {
                                            _cartManager.updateQuantity(
                                              item.id,
                                              -1,
                                            );
                                          }
                                        },
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      IconButton(
                                        icon: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.red.shade100,
                                          child: Icon(
                                            Icons.add,
                                            size: 16,
                                            color:
                                                themeNotifier
                                                        .isSpecialModeActive
                                                    ? themeNotifier
                                                        .getThemeColor(
                                                          themeNotifier
                                                              .specialTheme,
                                                        )
                                                    : Colors.red,
                                          ),
                                        ),
                                        onPressed:
                                            () => _cartManager.updateQuantity(
                                              item.id,
                                              1,
                                            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
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
                                    filled: true,
                                    fillColor:
                                        Theme.of(
                                          context,
                                        ).inputDecorationTheme.fillColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      themeNotifier.isSpecialModeActive
                                          ? themeNotifier.getThemeColor(
                                            themeNotifier.specialTheme,
                                          )
                                          : Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed:
                                    _isApplyingDiscount
                                        ? null
                                        : _applyDiscountCode,
                                child:
                                    _isApplyingDiscount
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text('APPLY'),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.discount_outlined,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Discount applied: ${_appliedDiscount!.code}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                      Text(
                                        '${_appliedDiscount!.discountPercentage}% off',
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _removeDiscount,
                                  icon: const Icon(
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_appliedDiscount != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                '₺${_cartManager.totalPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                          const Divider(height: 20),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₺${_discountedTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    themeNotifier.isSpecialModeActive
                                        ? themeNotifier.getThemeColor(
                                          themeNotifier.specialTheme,
                                        )
                                        : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  themeNotifier.isSpecialModeActive
                                      ? themeNotifier.getThemeColor(
                                        themeNotifier.specialTheme,
                                      )
                                      : Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                cartItems.isEmpty || _isProcessingPayment
                                    ? null
                                    : _proceedToCheckout,
                            child:
                                _isProcessingPayment
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
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
