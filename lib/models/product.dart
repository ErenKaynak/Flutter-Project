import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final String imageUrl;
  final double averageRating;
  final int ratingCount;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.stock = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'description': description,
    'imageUrl': imageUrl,
    'averageRating': averageRating,
    'ratingCount': ratingCount,
    'stock': stock,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    category: json['category'],
    price: json['price'].toDouble(),
    description: json['description'],
    imageUrl: json['imageUrl'],
    averageRating: json['averageRating']?.toDouble() ?? 0.0,
    ratingCount: json['ratingCount'] ?? 0,
    stock: json['stock'] ?? 0,
  );

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] is int) 
          ? (data['price'] as int).toDouble() 
          : (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      imageUrl: data['imagePath'] ?? '',
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      stock: data['stock'] ?? 0,
    );
  }
}