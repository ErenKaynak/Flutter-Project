import 'package:engineering_project/pages/home_page.dart';
import 'package:engineering_project/pages/root_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// Utility function to convert INR to USD
double convertToUSD(String priceInINR) {
  final price = double.tryParse(priceInINR) ?? 0;
  const exchangeRate = 0.012; // 1 INR = 0.012 USD (as of March 31, 2025; adjust if needed)
  return price * exchangeRate;
}

// CartItem class
class CartItem {
  final String id;
  final String name;
  final String price; // Price in INR
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
}

// Cart Manager class using Firestore
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

    // Cancel any existing subscription first
    await _cartSubscription?.cancel();

    // Set up a stream subscription to listen for cart changes
    _cartSubscription = _firestore
        .collection('cart')
        .doc(user.uid)
        .collection('userCart')
        .snapshots()
        .listen((snapshot) {
      _cartItems = snapshot.docs.map((doc) => CartItem.fromFirestore(doc)).toList();
      print('Cart loaded: ${_cartItems.length} items');
      _notifyListeners();
    }, onError: (error) {
      print('Error loading cart: $error');
      _cartItems = [];
      _notifyListeners();
    });
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
      double itemPrice = convertToUSD(item.price);
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

// OrderSuccessPage
class OrderSuccessPage extends StatelessWidget {
  final double totalAmount;

  const OrderSuccessPage({Key? key, required this.totalAmount}) : super(key: key);

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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Amount Paid: \$${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your order has been placed successfully.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
    _cartManager.dispose();
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
      final totalAmount = _cartManager.totalPrice;
      final orderDescription = 'Purchase from Your Store: ${_cartManager.itemCount} items';
      print('Processing order: $orderDescription, Total: \$${totalAmount.toStringAsFixed(2)}');

      // Simulate a successful payment and navigate to success page
      await Future.delayed(const Duration(seconds: 2)); // Simulate delay
      await _cartManager.clearCart(); // Clear cart after successful payment

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderSuccessPage(totalAmount: totalAmount),
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
    // Show loading indicator while checking login and loading cart
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Your Cart',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show login error if user is not logged in
    if (_loginError != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Your Cart',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              Text(
                _loginError!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // Navigate to login page
                  // Replace with your login navigation
                  Navigator.of(context).pop();
                },
                child: const Text('GO TO LOGIN'),
              ),
            ],
          ),
        ),
      );
    }

    final cartItems = _cartManager.items;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Your Cart',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text('Are you sure you want to remove all items?'),
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
                        child: const Text('CLEAR', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.red,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Add items to your cart to checkout',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
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
                          color: Colors.red,
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (direction) {
                          final removedItem = item;
                          _cartManager.removeItem(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} removed from cart'),
                              action: SnackBarAction(
                                label: 'UNDO',
                                onPressed: () {
                                  // Undo logic would go here - you'd need to add a method to re-add items
                                  // This would require additional implementation to fully support
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
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
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: (item.image.startsWith('http') || item.image.startsWith('https'))
                                        ? Image.network(
                                            item.image,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.image,
                                                color: Colors.grey,
                                              );
                                            },
                                          )
                                        : Image.asset(
                                            item.image,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.image,
                                                color: Colors.grey,
                                              );
                                            },
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${convertToUSD(item.price).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.red,
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
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.remove,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                      ),
                                      onPressed: () => _cartManager.updateQuantity(item.id, -1),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 16,
                                          color: Colors.red,
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
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
                            '\$${_cartManager.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: cartItems.isEmpty || _isProcessingPayment
                              ? null
                              : _processPayment,
                          child: _isProcessingPayment
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