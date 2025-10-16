import 'package:cloud_firestore/cloud_firestore.dart';

class LocalizedProduct {
  final String id;
  final String name;
  final String category;
  final double price;
  final Map<String, String> descriptions;
  final String imageUrl;
  final List<String> images;
  final double averageRating;
  final int ratingCount;
  final int stock;
  final String? specifications;

  LocalizedProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.descriptions,
    required this.imageUrl,
    required this.images,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.stock = 0,
    this.specifications,
  });

  String getDescription(String languageCode) {
    print('Getting description for language: $languageCode');
    print('Available descriptions: $descriptions');
    
    // First try the exact language code
    if (descriptions.containsKey(languageCode)) {
      return descriptions[languageCode]!;
    }
    
    // Then try English as fallback
    if (descriptions.containsKey('en')) {
      return descriptions['en']!;
    }
    
    // Finally, return the first available description or default message
    return descriptions.values.firstOrNull ?? 'No description available.';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'descriptions': descriptions,
    'imageUrl': imageUrl,
    'images': images,
    'averageRating': averageRating,
    'ratingCount': ratingCount,
    'stock': stock,
    'specifications': specifications,
  };

  factory LocalizedProduct.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    print('Converting Firestore data to LocalizedProduct: $data');
    
    // Handle descriptions
    Map<String, String> descriptions = {};
    if (data['descriptions'] != null) {
      print('Found descriptions field: ${data['descriptions']}');
      final descData = data['descriptions'] as Map<String, dynamic>;
      descriptions = descData.map((key, value) => MapEntry(key, value.toString()));
    } else if (data['description'] != null) {
      print('Using legacy description field: ${data['description']}');
      descriptions = {'en': data['description'].toString()};
    }
    print('Final descriptions map: $descriptions');

    return LocalizedProduct(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] is int) 
          ? (data['price'] as int).toDouble() 
          : (data['price'] ?? 0).toDouble(),
      descriptions: descriptions,
      imageUrl: data['imagePath'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      stock: data['stock'] ?? 0,
      specifications: data['specifications']?.toString(),
    );
  }
} 