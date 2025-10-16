import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  List<CartItem> _items = [];
  StreamSubscription<QuerySnapshot>? _cartSubscription;

  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  void addItem(CartItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(item);
    }
    notifyListeners();
    saveCart();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    saveCart();
  }

  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
      saveCart();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
    saveCart();
  }

  Future<void> loadCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _items = [];
      notifyListeners();
      return;
    }

    await _cartSubscription?.cancel();

    _cartSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .snapshots()
        .listen(
      (snapshot) {
        _items = snapshot.docs.map((doc) {
          final data = doc.data();
          return CartItem(
            id: doc.id,
            name: data['name'] ?? 'Unknown Product',
            price: double.tryParse(data['price']?.toString() ?? '0') ?? 0.0,
            imagePath: data['imagePath'] ?? 'lib/assets/Images/placeholder.png',
            quantity: data['quantity'] ?? 1,
          );
        }).toList();
        notifyListeners();
      },
      onError: (error) {
        print('Error loading cart: $error');
        _items = [];
        notifyListeners();
      },
    );
  }

  Future<void> saveCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');

      final existingItems = await cartRef.get();
      for (var doc in existingItems.docs) {
        batch.delete(doc.reference);
      }

      for (var item in _items) {
        final docRef = cartRef.doc(item.id);
        batch.set(docRef, {
          'name': item.name,
          'price': item.price.toString(),
          'imagePath': item.imagePath,
          'quantity': item.quantity,
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }
}

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imagePath;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    this.quantity = 1,
  });
} 