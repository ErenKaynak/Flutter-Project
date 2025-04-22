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
    this.isDefault = false,  
  });  
    
  factory CreditCard.fromMap(Map<String, dynamic> map) {    
    return CreditCard(      
      id: map['id'] ?? '',      
      cardNumber: map['cardNumber'] ?? '',      
      cardHolder: map['cardHolder'] ?? '',      
      expiryDate: map['expiryDate'] ?? '',      
      cvv: map['cvv'] ?? '',  // Add this      
      isDefault: map['isDefault'] ?? false,    
    );  
  }  
  
  Map<String, dynamic> toMap() {    
    return {      
      'id': id,      
      'cardNumber': cardNumber,      
      'cardHolder': cardHolder,      
      'expiryDate': expiryDate,      
      'cvv': cvv,  // Add this      
      'isDefault': isDefault,    
    };  
  }
}