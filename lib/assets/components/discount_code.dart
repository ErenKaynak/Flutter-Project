import 'package:cloud_firestore/cloud_firestore.dart';

class DiscountCode {
  final String id;
  final String code;
  final double discountPercentage;
  final DateTime? expiryDate; // null means no expiration (infinity)
  final List<String>? applicableCategories; // null means applicable to all products
  final int usageLimit; // maximum number of times the code can be used
  final int usageCount; // number of times the code has been used

  DiscountCode({
    required this.id,
    required this.code,
    required this.discountPercentage,
    this.expiryDate,
    this.applicableCategories,
    this.usageLimit = 0, // 0 means unlimited
    this.usageCount = 0,
  });

  factory DiscountCode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return DiscountCode(
      id: doc.id,
      code: data['code'] ?? '',
      discountPercentage: (data['discountPercentage'] ?? 0).toDouble(),
      expiryDate: data['expiryDate'] != null ? (data['expiryDate'] as Timestamp).toDate() : null,
      applicableCategories: data['applicableCategories'] != null 
          ? List<String>.from(data['applicableCategories']) 
          : null,
      usageLimit: data['usageLimit'] ?? 0,
      usageCount: data['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discountPercentage': discountPercentage,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'applicableCategories': applicableCategories,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
    };
  }

  bool isValid() {
    final now = DateTime.now();
    
    // Check expiration
    if (expiryDate != null && now.isAfter(expiryDate!)) {
      return false;
    }
    
    // Check usage limit
    if (usageLimit > 0 && usageCount >= usageLimit) {
      return false;
    }
    
    return true;
  }

  bool isApplicableToCategory(String category) {
    // If no categories specified, applicable to all
    if (applicableCategories == null || applicableCategories!.isEmpty) {
      return true;
    }
    
    return applicableCategories!.contains(category);
  }

  double calculateDiscount(double originalPrice) {
    return originalPrice * (discountPercentage / 100);
  }
}



