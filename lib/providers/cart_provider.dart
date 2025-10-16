import 'package:flutter/foundation.dart';
import 'package:engineering_project/models/product.dart';

class CartProvider with ChangeNotifier {
  final List<Product> _items = [];
  
  List<Product> get items => [..._items];
  
  int get itemCount => _items.length;
  
  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.price);
  }

  void addItem(Product product) {
    _items.add(product);
    notifyListeners();
  }

  void removeItem(Product product) {
    _items.remove(product);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}