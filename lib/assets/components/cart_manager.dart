import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String image;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'],
        name: json['name'],
        price: (json['price'] as num).toDouble(),
        image: json['image'],
        quantity: json['quantity'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'image': image,
        'quantity': quantity,
      };
}

class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('cart');
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      _items.clear();
      _items.addAll(jsonList.map((e) => CartItem.fromJson(e)));
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _items.map((e) => e.toJson()).toList();
    await prefs.setString('cart', json.encode(jsonList));
  }

  Future<void> addToCart(Map<String, dynamic> product) async {
    final index = _items.indexWhere((item) => item.id == product['id']);
    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(
        id: product['id'],
        name: product['name'],
        price: (product['price'] as num).toDouble(),
        image: product['image'],
        quantity: 1,
      ));
    }
    await _saveCart();
  }

  Future<void> removeFromCart(String productId) async {
    _items.removeWhere((item) => item.id == productId);
    await _saveCart();
  }

  Future<void> clearCart() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart');
  }

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
}