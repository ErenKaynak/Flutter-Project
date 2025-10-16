class CreditCard {  
  final String id;  
  final String cardNumber;  
  final String cardHolder;  
  final String expiryDate;  
  final String cvv;  // Add this  
  final bool isDefault;  
  
  CreditCard({    
    required this.id,    
    required this.cardNumber,    
    required this.cardHolder,    
    required this.expiryDate,    
    required this.cvv,  // Add this    
    required this.isDefault,  
  });  
    
  factory CreditCard.fromMap(Map<String, dynamic> map) {    
    return CreditCard(      
      id: map['id']?.toString() ?? '',      
      cardNumber: map['cardNumber']?.toString() ?? '',      
      cardHolder: map['cardHolder']?.toString() ?? '',      
      expiryDate: map['expiryDate']?.toString() ?? '',      
      cvv: map['cvv']?.toString() ?? '',      
      isDefault: map['isDefault'] as bool? ?? false,    
    );  
  }  
  
  Map<String, dynamic> toMap() {    
    return {      
      'cardNumber': cardNumber,      
      'cardHolder': cardHolder,      
      'expiryDate': expiryDate,      
      'cvv': cvv,  // Add this      
      'isDefault': isDefault,    
    };  
  }
}