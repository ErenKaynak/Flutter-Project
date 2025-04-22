class CreditCard {
  final String id;
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final bool isDefault;

  CreditCard({
    required this.id,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardNumber': cardNumber,
      'cardHolder': cardHolder,
      'expiryDate': expiryDate,
      'isDefault': isDefault,
    };
  }

  factory CreditCard.fromMap(Map<String, dynamic> map) {
    return CreditCard(
      id: map['id'],
      cardNumber: map['cardNumber'],
      cardHolder: map['cardHolder'],
      expiryDate: map['expiryDate'],
      isDefault: map['isDefault'] ?? false,
    );
  }
}