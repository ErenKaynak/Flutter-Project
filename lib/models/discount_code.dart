import 'package:cloud_firestore/cloud_firestore.dart';

class DiscountCode {
  final String id;
  final String code;
  final String description;
  final double value;
  final DateTime? validFrom;
  final DateTime? expiryDate;
  final bool isPercent;
  final bool isUsed;
  final int? maxUses;
  final int? perUserLimit;
  final DateTime receivedAt;

  DiscountCode({
    required this.id,
    required this.code,
    required this.description,
    required this.value,
    this.validFrom,
    this.expiryDate,
    required this.isPercent,
    this.isUsed = false,
    this.maxUses,
    this.perUserLimit,
    required this.receivedAt,
  });

  factory DiscountCode.fromJson(Map<String, dynamic> json) {
    return DiscountCode(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String,
      value: (json['value'] as num).toDouble(),
      validFrom: json['validFrom'] != null ? (json['validFrom'] as Timestamp).toDate() : null,
      expiryDate: json['expiryDate'] != null ? (json['expiryDate'] as Timestamp).toDate() : null,
      isPercent: json['isPercent'] as bool,
      isUsed: json['isUsed'] as bool,
      maxUses: json['maxUses'] as int?,
      perUserLimit: json['perUserLimit'] as int?,
      receivedAt: json['receivedAt'] != null ? 
                 (json['receivedAt'] as Timestamp).toDate() : 
                 DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'value': value,
      'validFrom': validFrom != null ? Timestamp.fromDate(validFrom!) : null,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'isPercent': isPercent,
      'isUsed': isUsed,
      'maxUses': maxUses,
      'perUserLimit': perUserLimit,
      'receivedAt': Timestamp.fromDate(receivedAt),
    };
  }

  bool get isValid {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) {
      return false;
    }
    if (expiryDate != null && now.isAfter(expiryDate!)) {
      return false;
    }
    return !isUsed;
  }

  String getFormattedValue() {
    if (isPercent) {
      return '${value.toStringAsFixed(0)}%';
    } else {
      return '\$${value.toStringAsFixed(2)}';
    }
  }
}
