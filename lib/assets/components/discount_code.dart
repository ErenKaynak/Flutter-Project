import 'package:cloud_firestore/cloud_firestore.dart';

class DiscountCode {
  final String id;
  final String code;
  final String name;
  final String description;
  final double discountPercentage;
  final double minOrderAmount;
  final DateTime? expiryDate;
  final List<String>? applicableCategories;
  final int usageLimit;
  final int usageCount;
  final bool isActive;
  final int perUserLimit; // New field for per-user usage limit

  const DiscountCode({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.discountPercentage,
    required this.minOrderAmount,
    this.expiryDate,
    this.applicableCategories,
    this.usageLimit = 0,
    this.usageCount = 0,
    this.isActive = true,
    this.perUserLimit = 0, // Default to 0 (unlimited) if not specified
  });

  double calculateDiscount(double originalAmount) {
    return (originalAmount * discountPercentage) / 100;
  }

  bool isValid() {
    if (!isActive) return false;
    if (expiryDate != null && DateTime.now().isAfter(expiryDate!)) return false;
    if (usageLimit > 0 && usageCount >= usageLimit) return false;
    return true;
  }

  bool isApplicableToCategory(String category) {
    if (applicableCategories == null || applicableCategories!.isEmpty) return true;
    return applicableCategories!.contains(category);
  }

  factory DiscountCode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiscountCode(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      discountPercentage: (data['discountPercentage'] ?? 0).toDouble(),
      minOrderAmount: (data['minOrderAmount'] ?? 0).toDouble(),
      expiryDate: data['expiryDate'] != null 
          ? (data['expiryDate'] as Timestamp).toDate() 
          : null,
      applicableCategories: data['applicableCategories'] != null 
          ? List<String>.from(data['applicableCategories']) 
          : null,
      usageLimit: data['usageLimit'] ?? 0,
      usageCount: data['usageCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      perUserLimit: data['perUserLimit'] ?? 0,
    );
  }

  factory DiscountCode.fromMap(Map<String, dynamic> data, String docId) {
    return DiscountCode(
      id: docId,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      discountPercentage: (data['discountPercentage'] ?? 0).toDouble(),
      minOrderAmount: (data['minOrderAmount'] ?? 0).toDouble(),
      expiryDate: data['expiryDate'] != null 
          ? (data['expiryDate'] as Timestamp).toDate() 
          : null,
      applicableCategories: data['applicableCategories'] != null 
          ? List<String>.from(data['applicableCategories']) 
          : null,
      usageLimit: data['usageLimit'] ?? 0,
      usageCount: data['usageCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      perUserLimit: data['perUserLimit'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'discountPercentage': discountPercentage,
      'minOrderAmount': minOrderAmount,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'applicableCategories': applicableCategories,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'isActive': isActive,
      'perUserLimit': perUserLimit,
    };
  }
}



