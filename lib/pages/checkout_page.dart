import 'package:engineering_project/assets/components/discount_code.dart';
import 'package:engineering_project/models/credit_card.dart';
import 'package:engineering_project/pages/add_address_page.dart';
import 'package:engineering_project/pages/past_orders_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:engineering_project/pages/cart_page.dart';

class CheckoutPage extends StatefulWidget {
  final double subtotal;
  final DiscountCode? appliedDiscount;
  final List<CartItem> items;

  const CheckoutPage({
    Key? key,
    required this.subtotal,
    this.appliedDiscount,
    required this.items,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Map<String, dynamic>? _selectedAddress;
  String _selectedPaymentMethod = 'Credit Card';
  bool _isLoading = true;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _savedAddresses = [];
  final _addressController = TextEditingController();

  List<CreditCard> _savedCards = [];
  CreditCard? _selectedCard;
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
    _loadSavedCards();
    _fetchWalletBalance(); // Add this line
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  double get shippingCost => widget.subtotal >= 10000 ? 0.0 : 400.0;

  double get total {
    double total = widget.subtotal;
    if (widget.appliedDiscount != null) {
      total -= widget.appliedDiscount!.calculateDiscount(widget.subtotal);
    }
    return total + shippingCost;
  }

  Future<void> _loadSavedAddresses() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot =
            await FirebaseFirestore.instance
                .collection('addresses')
                .where('userId', isEqualTo: user.uid)
                .orderBy('createdAt', descending: true)
                .get();

        final addresses =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'label': data['label'] ?? 'Address',
                'fullAddress': _formatAddress(data),
                'firstName': data['firstName'] ?? '',
                'lastName': data['lastName'] ?? '',
                'phone': data['phone'] ?? '',
                'addressType': data['addressType'] ?? 'Home',
              };
            }).toList();

        setState(() {
          _savedAddresses = addresses;
          if (addresses.isNotEmpty) {
            _selectedAddress = addresses.first;
          }
        });
      }
    } catch (e) {
      print('Error loading addresses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedCards() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cards')
            .get();

        setState(() {
          _savedCards = snapshot.docs
              .map((doc) => CreditCard.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          
          if (_savedCards.isNotEmpty) {
            _selectedCard = _savedCards.firstWhere(
              (card) => card.isDefault,
              orElse: () => _savedCards.first,
            );
          }
        });
      }
    } catch (e) {
      print('Error loading cards: $e');
    }
  }

  Future<void> _fetchWalletBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _walletBalance = (doc.data()?['balance'] ?? 0.0).toDouble();
        });
      }
    } catch (e) {
      print('Error fetching wallet balance: $e');
    }
  }

  String _formatAddress(Map<String, dynamic> data) {
    String address = '';
    if (data['street'] != null) address += data['street'];
    if (data['buildingNo'] != null) address += ' No:${data['buildingNo']}';
    if (data['doorNo'] != null) address += ' D${data['doorNo']}';
    if (data['apartment'] != null)
      address += ', ${data['apartment']} Apartment';
    if (data['neighborhood'] != null)
      address = '${data['neighborhood']}, $address';
    if (data['city'] != null) address += ', ${data['city']}';
    return address;
  }

  Future<void> _showAddAddressDialog() async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Address'),
            content: TextField(
              controller: _addressController,
              decoration: const InputDecoration(hintText: 'Enter your address'),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () async {
                  if (_addressController.text.isNotEmpty) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({
                            'addresses': FieldValue.arrayUnion([
                              _addressController.text,
                            ]),
                          });
                      _addressController.clear();
                      Navigator.pop(context);
                      _loadSavedAddresses();
                    }
                  }
                },
                child: const Text('SAVE'),
              ),
            ],
          ),
    );
  }

  Future<void> _addNewCard() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Add New Card',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _cardNumberController,
                  decoration: InputDecoration(
                    labelText: 'Card Number',
                    hintText: '1234 5678 9012 3456',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                  onChanged: (value) {
                    if (value.length > 0) {
                      value = value.replaceAll(' ', '');
                      final buffer = StringBuffer();
                      for (int i = 0; i < value.length; i++) {
                        buffer.write(value[i]);
                        if ((i + 1) % 4 == 0 && i != value.length - 1) {
                          buffer.write(' ');
                        }
                      }
                      _cardNumberController.value = TextEditingValue(
                        text: buffer.toString(),
                        selection: TextSelection.collapsed(offset: buffer.length),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cardHolderController,
                  decoration: InputDecoration(
                    labelText: 'Card Holder Name',
                    hintText: 'JOHN DOE',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _expiryDateController,
                        decoration: InputDecoration(
                          labelText: 'Expiry Date',
                          hintText: 'MM/YY',
                          prefixIcon: Icon(Icons.date_range),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorText: _expiryDateController.text.isNotEmpty && 
                                     _isCardExpired(_expiryDateController.text)
                              ? 'Card is expired'
                              : null,
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        onChanged: _formatExpiryDate,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _cvvController,
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          hintText: '123',
                          prefixIcon: Icon(Icons.security),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_validateCardInputs()) {
                await _saveCard();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  bool _validateCardInputs() {
    if (_cardNumberController.text.isEmpty ||
        _cardHolderController.text.isEmpty ||
        _expiryDateController.text.isEmpty ||
        _cvvController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return false;
    }

    if (_isCardExpired(_expiryDateController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your card is expired, please try again')),
      );
      return false;
    }

    return true;
  }

  Future<void> _saveCard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cardRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .doc();

      await cardRef.set({
        'cardNumber': _cardNumberController.text,
        'cardHolder': _cardHolderController.text,
        'expiryDate': _expiryDateController.text,
        'cvv': _cvvController.text,
        'isDefault': _savedCards.isEmpty,
      });

      _cardNumberController.clear();
      _cardHolderController.clear();
      _expiryDateController.clear();
      _cvvController.clear();
      _loadSavedCards();
    }
  }

  Future<void> _processOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an address')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      bool paymentSuccess = false;

      if (_selectedPaymentMethod == 'Wallet') {
        paymentSuccess = await _processWalletPayment(total);
      } else if (_selectedPaymentMethod == 'Credit Card') {
        // Your existing credit card payment logic
      }

      if (paymentSuccess) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not logged in');

        final batch = FirebaseFirestore.instance.batch();
        final orderRef = FirebaseFirestore.instance.collection('orders').doc();

        // Create order data
        final orderData = {
          'userId': user.uid,
          'orderNumber': orderRef.id.substring(0, 8),
          'items': widget.items.map((item) => item.toMap()).toList(),
          'subtotal': widget.subtotal,
          'shippingCost': shippingCost,
          'discountCode': widget.appliedDiscount?.code,
          'discountPercentage': widget.appliedDiscount?.discountPercentage ?? 0.0,
          'discountAmount': widget.appliedDiscount?.calculateDiscount(widget.subtotal) ?? 0.0,
          'totalAmount': total,  // This includes the discounted amount
          'total': total,       // Add this as a backup
          'status': 'Pending',
          'paymentMethod': _selectedPaymentMethod,
          'paymentDetails': _selectedPaymentMethod == 'Credit Card'
              ? {
                  'cardId': _selectedCard?.id,
                  'lastFourDigits': _selectedCard?.cardNumber.substring(_selectedCard!.cardNumber.length - 4),
                }
              : null,
          'shippingAddress': _selectedAddress!['fullAddress'],
          'addressDetails': _selectedAddress,
          'timestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'customerName':
              '${_selectedAddress!['firstName']} ${_selectedAddress!['lastName']}',
          'customerPhone': _selectedAddress!['phone'],
          'customerEmail': user.email,
          'trackingNumber': '',
        };

        // Add order to main orders collection
        batch.set(orderRef, orderData);

        // Add order to user's orders subcollection
        final userOrderRef = FirebaseFirestore.instance
            .collection('users')  // Change to users collection
            .doc(user.uid)
            .collection('orders')  // Change to orders subcollection
            .doc(orderRef.id);

        batch.set(userOrderRef, orderData);

        // Update product stock
        for (var item in widget.items) {
          final productRef = FirebaseFirestore.instance
              .collection('products')
              .doc(item.id);
          batch.update(productRef, {
            'stock': FieldValue.increment(-item.quantity),
          });
        }

        if (widget.appliedDiscount != null) {
          try {
            final discountRef = FirebaseFirestore.instance
                .collection('discountCodes')
                .doc(widget.appliedDiscount!.code.toLowerCase()); // Convert to lowercase
            
            // Create the discount code document if it doesn't exist
            batch.set(discountRef, {
              'code': widget.appliedDiscount!.code,
              'discountPercentage': widget.appliedDiscount!.discountPercentage,
              'usageCount': FieldValue.increment(1),
              'usageLimit': widget.appliedDiscount!.usageLimit,
              'expiryDate': widget.appliedDiscount!.expiryDate,
              'isActive': true,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true)); // Use merge to update existing document
          } catch (e) {
            print('Error updating discount code usage: $e');
          }
        }

        // Commit all changes
        await batch.commit();

        // Clear the cart
        final cartManager = CartManager();
        await cartManager.clearCart();

        // Navigate to success page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => OrderSuccessPage(
                    orderId: orderRef.id,
                    totalAmount: total,
                  ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing order: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  bool _isCardExpired(String expiryDate) {
    try {
      final parts = expiryDate.split('/');
      if (parts.length != 2) return true;

      final month = int.parse(parts[0]);
      final year = 2000 + int.parse(parts[1]); // Convert YY to 20YY

      final now = DateTime.now();
      final cardExpiry = DateTime(year, month + 1, 0); // Last day of expiry month

      return cardExpiry.isBefore(DateTime(now.year, now.month, 1));
    } catch (e) {
      return true;
    }
  }

  void _formatExpiryDate(String value) {
    if (value.length > 0) {
      value = value.replaceAll('/', '');
      if (value.length >= 2) {
        final month = int.tryParse(value.substring(0, 2)) ?? 0;
        if (month > 12) {
          value = '12' + value.substring(2);
        }
      }
      final buffer = StringBuffer();
      for (int i = 0; i < value.length; i++) {
        buffer.write(value[i]);
        if (i == 1 && i != value.length - 1) {
          buffer.write('/');
        }
      }
      _expiryDateController.value = TextEditingValue(
        text: buffer.toString(),
        selection: TextSelection.collapsed(offset: buffer.length),
      );
    }
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Delivery Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddAddressPage()),
                );
                if (result == true) {
                  _loadSavedAddresses();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_savedAddresses.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No saved addresses'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _savedAddresses.length,
            itemBuilder: (context, index) {
              final address = _savedAddresses[index];
              final bool isSelected = _selectedAddress?['id'] == address['id'];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Colors.red : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: RadioListTile(
                  value: address,
                  groupValue: _selectedAddress,
                  onChanged: (value) {
                    setState(() => _selectedAddress = value);
                  },
                  title: Row(
                    children: [
                      Icon(
                        address['addressType'] == 'Home'
                            ? Icons.home
                            : Icons.work,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        address['label'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('${address['firstName']} ${address['lastName']}'),
                      Text(address['fullAddress']),
                      Text(address['phone']),
                    ],
                  ),
                  isThreeLine: true,
                  contentPadding: const EdgeInsets.all(8),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCreditCardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Credit Cards',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _addNewCard,
              icon: const Icon(Icons.add),
              label: const Text('Add New'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_savedCards.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No saved cards'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _savedCards.length,
            itemBuilder: (context, index) {
              final card = _savedCards[index];
              final isSelected = _selectedCard?.id == card.id;

              return Dismissible(
                key: Key(card.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Card'),
                      content: const Text('Are you sure you want to delete this card?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('DELETE'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('cards')
                        .doc(card.id)
                        .delete();
                    _loadSavedCards();
                  }
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Colors.red : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: RadioListTile<CreditCard>(
                    value: card,
                    groupValue: _selectedCard,
                    onChanged: (value) {
                      setState(() => _selectedCard = value);
                    },
                    title: Row(
                      children: [
                        const Icon(Icons.credit_card, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          '**** ${card.cardNumber.substring(card.cardNumber.length - 4)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.cardHolder),
                        Text('Expires: ${card.expiryDate}'),
                        if (card.isDefault)
                          const Text(
                            'Default Card',
                            style: TextStyle(color: Colors.green),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildOrderItemsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 0 : 2,
      color: isDark ? Colors.grey.shade900 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.items.length,
        separatorBuilder: (context, index) => Divider(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₺${item.price} × ${item.quantity}',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Total Price
                Text(
                  '₺${(double.parse(item.price) * item.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Order Progress Indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Colors.red.shade900, Colors.grey.shade900]
                            : [Colors.red.shade500, Colors.red.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black12
                              : Colors.red.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProgressStep(1, 'Address', true),
                        _buildProgressLine(true),
                        _buildProgressStep(
                            2, 'Payment', _selectedAddress != null),
                        _buildProgressLine(_selectedAddress != null),
                        _buildProgressStep(3, 'Confirm', false),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address Section
                        _buildSectionTitle('Delivery Address'),
                        const SizedBox(height: 8),
                        _buildAddressSection(),
                        const SizedBox(height: 24),

                        // Payment Method Section
                        _buildSectionTitle('Payment Method'),
                        const SizedBox(height: 8),
                        Card(
                          elevation: isDark ? 0 : 2,
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildPaymentOption(
                                  'Credit Card', 'Pay with credit card'),
                              Divider(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200),
                              _buildPaymentOption('Cash on Delivery',
                                  'Pay when you receive'),
                            ],
                          ),
                        ),
                        _buildWalletOption(),

                        if (_selectedPaymentMethod == 'Credit Card') ...[
                          const SizedBox(height: 24),
                          _buildSectionTitle('Credit Cards'),
                          const SizedBox(height: 8),
                          _buildCreditCardSection(),
                        ],

                        const SizedBox(height: 24),
                        _buildSectionTitle('Order Summary'),
                        const SizedBox(height: 8),
                        _buildOrderItemsList(),
                        const SizedBox(height: 12),
                        _buildOrderSummaryCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isProcessing
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'PLACE ORDER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? (isDark ? Colors.white : Colors.red)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? (isDark ? Colors.white : Colors.black)
                : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 40,
      height: 2,
      color: isActive
          ? (isDark ? Colors.white : Colors.red)
          : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPaymentOption(String title, String subtitle) {
    return RadioListTile<String>(
      value: title,
      groupValue: _selectedPaymentMethod,
      onChanged: (value) {
        setState(() => _selectedPaymentMethod = value!);
      },
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      activeColor: Colors.red,
    );
  }

  Widget _buildWalletOption() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _selectedPaymentMethod == 'Wallet' 
              ? Colors.red 
              : Colors.grey.shade300,
          width: _selectedPaymentMethod == 'Wallet' ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: 'Wallet',
        groupValue: _selectedPaymentMethod,
        onChanged: (value) {
          setState(() {
            _selectedPaymentMethod = value!;
          });
        },
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, 
                 color: _selectedPaymentMethod == 'Wallet' ? Colors.red : Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Wallet Balance',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available: ₺${_walletBalance.toStringAsFixed(2)}'),
            if (_walletBalance < total)
              Text(
                'Insufficient balance',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingForFree = 10000 - widget.subtotal;

    return Column(
      children: [
        if (remainingForFree > 0)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add ₺${remainingForFree.toStringAsFixed(2)} more to get free shipping!',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Card(
          elevation: isDark ? 0 : 2,
          color: isDark ? Colors.grey.shade900 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal', widget.subtotal),
                if (widget.appliedDiscount != null)
                  _buildSummaryRow(
                    'Discount (${widget.appliedDiscount!.discountPercentage}%)',
                    -widget.appliedDiscount!.calculateDiscount(widget.subtotal),
                    isDiscount: true,
                  ),
                _buildSummaryRow('Shipping', shippingCost),
                Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                _buildSummaryRow('Total', total, isTotal: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
    String? note,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFreeShipping = label == 'Shipping' && widget.subtotal >= 10000;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: isFreeShipping ? Colors.green : (isDiscount ? Colors.green : null),
                ),
              ),
              if (isFreeShipping) ...[
                const SizedBox(width: 8),
                Icon(Icons.local_shipping, color: Colors.green, size: 16),
              ],
            ],
          ),
          Row(
            children: [
              if (widget.subtotal < 10000 && label == 'Shipping')
                Text(
                  'Free over ₺10,000',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                isFreeShipping ? 'FREE' : '₺${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: isFreeShipping ? Colors.green : (isDiscount ? Colors.green : null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _processWalletPayment(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // Start a batch write
      final batch = FirebaseFirestore.instance.batch();
      final walletRef = FirebaseFirestore.instance.collection('wallets').doc(user.uid);
      
      // Calculate cashback
      final cashback = amount * 0.01; // 1% cashback

      // Update wallet balance
      batch.update(walletRef, {
        'balance': FieldValue.increment(-amount + cashback),
        'last_transaction': FieldValue.serverTimestamp(),
      });

      // Create transaction record with order reference
      // Create order reference first
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      
      final transactionRef = FirebaseFirestore.instance.collection('wallet_transactions').doc();
      batch.set(transactionRef, {
        'user_id': user.uid,
        'amount': amount,
        'type': 'purchase',
        'timestamp': FieldValue.serverTimestamp(),
        'cashback': cashback,
        'method': 'wallet_payment',
        'status': 'completed',
        'reference': 'Order #${orderRef.id.substring(0, 8)}', // Add order reference
        'order_id': orderRef.id, // Add full order ID
        'description': 'Payment for Order #${orderRef.id.substring(0, 8)}',
      });

      // Commit the batch
      await batch.commit();

      // Update local state
      setState(() {
        _walletBalance -= (amount - cashback);
      });

      return true;
    } catch (e) {
      print('Error processing wallet payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing payment: $e')),
        );
      }
      return false;
    }
  }
}
