import 'package:engineering_project/assets/components/discount_code.dart';
import 'package:engineering_project/models/credit_card.dart';
import 'package:engineering_project/pages/add_address_page.dart';
import 'package:engineering_project/pages/past_orders_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:engineering_project/pages/cart_page.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:engineering_project/assets/components/email_service.dart';
import 'dart:math';
import 'package:flutter/services.dart'; // Add this import

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
  bool _isAddingNewCard = false;
  bool _isCardFlipped = false;

  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeData();
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

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load all data in parallel
      await Future.wait([
        _loadSavedAddresses(),
        _loadSavedCards(),
        _fetchWalletBalance(),
      ]);
    } catch (e) {
      print('Error initializing checkout page: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('addresses')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final addresses = snapshot.docs.map((doc) {
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

      if (mounted) {
        setState(() {
          _savedAddresses = addresses;
          if (addresses.isNotEmpty) {
            _selectedAddress = addresses.first;
          }
        });
      }
    } catch (e) {
      print('Error loading addresses: $e');
    }
  }

  Future<void> _loadSavedCards() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .get();

      if (mounted) {
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
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
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
    final l10n = AppLocalizations.of(context)!;
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            l10n.addNewCard,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCardVisualization(
                    cardNumber: _cardNumberController.text,
                    cardHolderName: _cardHolderController.text,
                    expiryDate: _expiryDateController.text,
                    cvv: _cvvController.text,
                    isFlipped: _isCardFlipped,
                    onFlip: () {
                      setState(() {
                        _isCardFlipped = !_isCardFlipped;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cardNumberController,
                    decoration: InputDecoration(
                      labelText: l10n.cardNumber,
                      hintText: '1234 5678 9012 3456',
                      prefixIcon: Icon(Icons.credit_card),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                            selection: TextSelection.collapsed(
                              offset: buffer.length,
                            ),
                          );
                        }
                      },
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cardHolderController,
                    decoration: InputDecoration(
                      labelText: l10n.cardHolderName,
                      hintText: 'JOHN DOE',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expiryDateController,
                          decoration: InputDecoration(
                            labelText: l10n.expiryDate,
                            hintText: 'MM/YY',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorText: _expiryDateController.text.isNotEmpty &&
                                    _isCardExpired(_expiryDateController.text)
                                ? l10n.cardIsExpired
                                : null,
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _ExpiryDateFormatter(),
                          ],
                          onChanged: (value) {
                            if (value.length == 2 && !value.contains('/')) {
                              _expiryDateController.text = '$value/';
                              _expiryDateController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _expiryDateController.text.length),
                              );
                            }
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _cvvController,
                          decoration: InputDecoration(
                            labelText: l10n.cvv,
                            hintText: '123',
                            prefixIcon: Icon(Icons.security),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          obscureText: true,
                          onChanged: (value) => setState(() {}),
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
              onPressed: () {
                _cardNumberController.clear();
                _cardHolderController.clear();
                _expiryDateController.clear();
                _cvvController.clear();
                Navigator.pop(context);
              },
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_validateCardInputs()) {
                  await _saveCard();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Provider.of<ThemeNotifier>(context).isSpecialModeActive
                    ? Provider.of<ThemeNotifier>(context).getThemeColor(
                        Provider.of<ThemeNotifier>(context).specialTheme,
                      )
                    : Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateCardInputs() {
    final l10n = AppLocalizations.of(context)!;
    if (_cardNumberController.text.isEmpty ||
        _cardHolderController.text.isEmpty ||
        _expiryDateController.text.isEmpty ||
        _cvvController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllFields)),
      );
      return false;
    }

    if (_isCardExpired(_cardNumberController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cardExpired)),
      );
      return false;
    }

    return true;
  }

  Future<void> _saveCard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cardRef =
          FirebaseFirestore.instance
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
    final l10n = AppLocalizations.of(context)!;
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectAddress)),
      );
      return;
    }

    if (_selectedPaymentMethod == 'Credit Card' && _selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectCard)),
      );
      return;
    }

    if (_selectedPaymentMethod == 'Credit Card') {
      if (_selectedCard == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or add a credit card')),
        );
        return;
      }

      if (_isCardExpired(_selectedCard!.expiryDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your selected card is expired, please use another card')),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      bool paymentSuccess = false;
      String? createdOrderId;

      if (_selectedPaymentMethod == 'Wallet') {
        final orderRef = FirebaseFirestore.instance.collection('orders').doc();
        createdOrderId = orderRef.id;
        paymentSuccess = await _processWalletPayment(total, createdOrderId);
      } else if (_selectedPaymentMethod == 'Credit Card') {
        paymentSuccess = await _processCreditCardPayment(total);
      }

      if (paymentSuccess) {
        final batch = FirebaseFirestore.instance.batch();
        final orderRef = createdOrderId != null
            ? FirebaseFirestore.instance.collection('orders').doc(createdOrderId)
            : FirebaseFirestore.instance.collection('orders').doc();

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not logged in');

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data() as Map<String, dynamic>?;

        final orderData = {
          'userId': user.uid,
          'userEmail': user.email,
          'userName': userData?['name'] ?? user.displayName ?? 'Anonymous User',
          'items': widget.items.map((item) => item.toMap()).toList(),
          'totalAmount': total,
          'shippingAddress': _selectedAddress?['fullAddress'] ?? 'No address provided',
          'paymentMethod': _selectedPaymentMethod,
          'status': 'Pending',
          'timestamp': FieldValue.serverTimestamp(),
          'trackingNumber': '',
        };

        batch.set(orderRef, orderData);

        // Kullanıcıya özel sipariş belgesi oluşturuluyor
        final userOrderRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('userOrders')
            .doc(orderRef.id);

        batch.set(userOrderRef, orderData);

        // Send order confirmation email
        await EmailService.sendReceipt(
          context: context,
          customerEmail: user.email ?? '',
          customerName: userData?['name'] ?? user.displayName ?? 'Anonymous User',
          orderNumber: orderRef.id,
          items: widget.items.map((item) => item.toMap()).toList(),
          totalAmount: total,
          orderDate: DateTime.now(),
          shippingAddress: _selectedAddress?['fullAddress'] ?? 'No address provided',
        );

        // --- STOK GÜNCELLEME ---
        for (final item in widget.items) {
          final productId = item.id;
          final quantity = item.quantity;
          final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
          batch.update(productRef, {
            'stock': FieldValue.increment(-quantity),
          });
        }
        // --- STOK GÜNCELLEME SONU ---

        await batch.commit();

        // Clear the cart using the CartManager from cart_page.dart
        final cartManager = CartManager();
        await cartManager.clearCart();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderSuccessPage(
                orderId: orderRef.id,
                totalAmount: total,
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error processing order: $e')));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool> _processCreditCardPayment(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedCard == null) return false;

    try {
      await Future.delayed(Duration(seconds: 2));

      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': user.uid,
        'amount': amount,
        'paymentMethod': 'Credit Card',
        'cardLastFour': _selectedCard!.cardNumber.substring(
          _selectedCard!.cardNumber.length - 4,
        ),
        'cardId': _selectedCard!.id,
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'purchase',
      });

      return true;
    } catch (e) {
      print('Error processing credit card payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing credit card payment: $e')),
        );
      }
      return false;
    }
  }

  bool _isCardExpired(String expiryDate) {
    try {
      final parts = expiryDate.split('/');
      if (parts.length != 2) return true;

      final month = int.parse(parts[0]);
      final year = 2000 + int.parse(parts[1]);

      if (month < 1 || month > 12) return true;

      final now = DateTime.now();
      final cardExpiry = DateTime(year, month + 1, 0);

      return cardExpiry.isBefore(DateTime(now.year, now.month, 1));
    } catch (e) {
      return true;
    }
  }

  Widget _buildAddressSection() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddAddressPage()),
                );
                if (result == true) {
                  await _loadSavedAddresses();
                  if (mounted) {
                    setState(() {});
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addNew),
            ),
            if (_selectedAddress != null)
              TextButton.icon(
                onPressed: () async {
                  final addressDoc = await FirebaseFirestore.instance
                      .collection('addresses')
                      .doc(_selectedAddress!['id'])
                      .get();
                  
                  if (addressDoc.exists) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddAddressPage(
                          addressToEdit: addressDoc,
                        ),
                      ),
                    );
                    if (result == true) {
                      await _loadSavedAddresses();
                      if (mounted) {
                        setState(() {});
                      }
                    }
                  }
                },
                icon: const Icon(Icons.edit),
                label: Text(l10n.edit),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_savedAddresses.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(l10n.noSavedAddresses),
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
                    color: isSelected
                        ? (themeNotifier.isSpecialModeActive
                            ? themeNotifier.getThemeColor(
                              themeNotifier.specialTheme,
                            )
                            : Colors.red)
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: RadioListTile(
                  value: address,
                  groupValue: _selectedAddress,
                  onChanged: (value) {
                    setState(() {
                      _selectedAddress = value;
                    });
                  },
                  title: Row(
                    children: [
                      Icon(
                        address['addressType'] == 'Home'
                            ? Icons.home
                            : Icons.work,
                        color: themeNotifier.isSpecialModeActive
                            ? themeNotifier.getThemeColor(
                              themeNotifier.specialTheme,
                            )
                            : Colors.red,
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isAddingNewCard = !_isAddingNewCard;
                  if (!_isAddingNewCard) {
                    _cardNumberController.clear();
                    _cardHolderController.clear();
                    _expiryDateController.clear();
                    _cvvController.clear();
                  }
                });
              },
              icon: Icon(_isAddingNewCard ? Icons.close : Icons.add),
              label: Text(_isAddingNewCard ? l10n.cancel : l10n.addNew),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isAddingNewCard)
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AddCardForm(
              cardNumberController: _cardNumberController,
              cardHolderController: _cardHolderController,
              expiryDateController: _expiryDateController,
              cvvController: _cvvController,
              onSave: () async {
                if (_validateCardInputs()) {
                  await _saveCard();
                  setState(() {
                    _isAddingNewCard = false;
                  });
                }
              },
            ),
          ),
        if (_savedCards.isEmpty && !_isAddingNewCard)
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(l10n.noSavedCards),
            ),
          )
        else if (!_isAddingNewCard)
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
                  color: themeNotifier.isSpecialModeActive
                      ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                      : Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Card'),
                      content: const Text(
                        'Are you sure you want to delete this card?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('CANCEL'),
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
                      color: isSelected
                          ? (themeNotifier.isSpecialModeActive
                              ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                              : Colors.red)
                          : Colors.grey.shade300,
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
                        Icon(
                          Icons.credit_card,
                          color: themeNotifier.isSpecialModeActive
                              ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                              : Colors.red,
                        ),
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
                        Text(l10n.expires(card.expiryDate)),
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
        separatorBuilder:
            (context, index) => Divider(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatPrice(item.price),
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatDoublePrice(double.parse(item.price) * item.quantity),
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.checkout,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color:
                      themeNotifier.isSpecialModeActive
                          ? themeNotifier.getThemeColor(
                            themeNotifier.specialTheme,
                          )
                          : Colors.red,
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              isDark
                                  ? [
                                    themeNotifier.isSpecialModeActive
                                        ? themeNotifier
                                            .getThemeColor(
                                              themeNotifier.specialTheme,
                                            )
                                            .shade900
                                        : Colors.red.shade900,
                                    Colors.grey.shade900,
                                  ]
                                  : [
                                    themeNotifier.isSpecialModeActive
                                        ? themeNotifier
                                            .getThemeColor(
                                              themeNotifier.specialTheme,
                                            )
                                            .shade500
                                        : Colors.red.shade500,
                                    themeNotifier.isSpecialModeActive
                                        ? themeNotifier
                                            .getThemeColor(
                                              themeNotifier.specialTheme,
                                            )
                                            .shade100
                                        : Colors.red.shade100,
                                  ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                isDark
                                    ? Colors.black12
                                    : (themeNotifier.isSpecialModeActive
                                        ? themeNotifier
                                            .getThemeColor(
                                              themeNotifier.specialTheme,
                                            )
                                            .withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1)),
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
                            2,
                            'Payment',
                            _selectedAddress != null,
                          ),
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
                          _buildSectionTitle(l10n.deliveryAddress),
                          const SizedBox(height: 8),
                          _buildAddressSection(),
                          const SizedBox(height: 24),
                          _buildSectionTitle(l10n.payment),
                          const SizedBox(height: 8),
                          Card(
                            elevation: isDark ? 0 : 2,
                            color: isDark ? Colors.grey.shade900 : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color:
                                    isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildPaymentOption(
                                  'Credit Card',
                                  'Pay with credit card',
                                ),
                                Divider(
                                  color:
                                      isDark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade200,
                                ),
                                _buildWalletOption(),
                              ],
                            ),
                          ),
                          if (_selectedPaymentMethod == 'Credit Card') ...[
                            const SizedBox(height: 24),
                            _buildSectionTitle(l10n.creditCards),
                            const SizedBox(height: 8),
                            _buildCreditCardSection(),
                          ],
                          const SizedBox(height: 24),
                          _buildSectionTitle(l10n.orderSummary),
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
              backgroundColor:
                  themeNotifier.isSpecialModeActive
                      ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                      : Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child:
                _isProcessing
                    ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Text(
                      l10n.placeOrder,
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
    final l10n = AppLocalizations.of(context)!;
    final stepLabel = step == 1 ? l10n.address :
                     step == 2 ? l10n.payment :
                     l10n.confirm;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isActive
                    ? (isDark
                        ? Colors.white
                        : (themeNotifier.isSpecialModeActive
                            ? themeNotifier.getThemeColor(
                              themeNotifier.specialTheme,
                            )
                            : Colors.red))
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color:
                    isActive
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stepLabel,
          style: TextStyle(
            color:
                isActive
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Container(
      width: 40,
      height: 2,
      color:
          isActive
              ? (isDark
                  ? Colors.white
                  : (themeNotifier.isSpecialModeActive
                      ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                      : Colors.red))
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPaymentOption(String title, String subtitle) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    return RadioListTile<String>(
      value: title,
      groupValue: _selectedPaymentMethod,
      onChanged: (value) {
        setState(() => _selectedPaymentMethod = value!);
      },
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(title == 'Credit Card' ? l10n.payWithCreditCard : subtitle),
      activeColor:
          themeNotifier.isSpecialModeActive
              ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
              : Colors.red,
    );
  }

  Widget _buildWalletOption() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    return RadioListTile<String>(
      value: 'Wallet',
      groupValue: _selectedPaymentMethod,
      onChanged:
          _walletBalance >= total
              ? (value) {
                setState(() => _selectedPaymentMethod = value!);
              }
              : null,
      title: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color:
                _walletBalance >= total
                    ? (_selectedPaymentMethod == 'Wallet'
                        ? (themeNotifier.isSpecialModeActive
                            ? themeNotifier.getThemeColor(
                              themeNotifier.specialTheme,
                            )
                            : Colors.red)
                        : Colors.grey)
                    : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.payWithWallet,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _walletBalance >= total ? null : Colors.grey.shade400,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.availableBalance(_walletBalance.toStringAsFixed(2))),
          if (_walletBalance < total)
            Text(
              l10n.insufficientBalance,
              style: TextStyle(
                color:
                    themeNotifier.isSpecialModeActive
                        ? themeNotifier.getThemeColor(
                          themeNotifier.specialTheme,
                        )
                        : Colors.red,
                fontSize: 12,
              ),
            ),
        ],
      ),
      activeColor:
          themeNotifier.isSpecialModeActive
              ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
              : Colors.red,
    );
  }

  Widget _buildOrderSummaryCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingForFree = 10000 - widget.subtotal;
    final l10n = AppLocalizations.of(context)!;

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
                Icon(Icons.local_shipping, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.addMoreForFreeShipping(remainingForFree.toStringAsFixed(2)),
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
                _buildSummaryRow(l10n.subtotal, widget.subtotal),
                if (widget.appliedDiscount != null)
                  _buildSummaryRow(
                    l10n.discount(widget.appliedDiscount!.discountPercentage.round()),
                    -widget.appliedDiscount!.calculateDiscount(widget.subtotal),
                    isDiscount: true,
                  ),
                _buildSummaryRow(l10n.shipping, shippingCost),
                Divider(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                _buildSummaryRow(l10n.total, total, isTotal: true),
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFreeShipping = label == l10n.shipping && widget.subtotal >= 10000;

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
                  color:
                      isFreeShipping
                          ? Colors.green
                          : (isDiscount ? Colors.green : null),
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
              if (widget.subtotal < 10000 && label == l10n.shipping)
                Text(
                  l10n.freeShippingOver,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              const SizedBox(width: 8),
              Text(
                isFreeShipping ? l10n.free : formatDoublePrice(amount),
                style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color:
                      isFreeShipping
                          ? Colors.green
                          : (isDiscount ? Colors.green : null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _processWalletPayment(double amount, String orderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final walletRef = FirebaseFirestore.instance
          .collection('wallets')
          .doc(user.uid);

      final cashback = amount * 0.01;

      batch.update(walletRef, {
        'balance': FieldValue.increment(-amount + cashback),
        'last_transaction': FieldValue.serverTimestamp(),
      });

      final transactionRef =
          FirebaseFirestore.instance.collection('wallet_transactions').doc();
      batch.set(transactionRef, {
        'user_id': user.uid,
        'amount': amount,
        'type': 'purchase',
        'timestamp': FieldValue.serverTimestamp(),
        'cashback': cashback,
        'method': 'wallet_payment',
        'status': 'completed',
        'reference': 'Order #' + orderId,
        'order_id': orderId,
        'description': 'Payment for Order #' + orderId,
      });

      await batch.commit();

      setState(() {
        _walletBalance -= (amount - cashback);
      });

      return true;
    } catch (e) {
      print('Error processing wallet payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing payment: $e')));
      }
      return false;
    }
  }

  String formatPrice(String price) {
    try {
      final double numericPrice = double.parse(price);
      return '₺${numericPrice.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    } catch (e) {
      return '₺0.00';
    }
  }

  String formatDoublePrice(double price) {
    return '₺${price.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  Widget _buildCardVisualization({
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
    required bool isFlipped,
    required VoidCallback onFlip,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isSpecialMode = themeNotifier.isSpecialModeActive;
    final specialThemeColor = themeNotifier.getThemeColor(themeNotifier.specialTheme);

    final embossTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          blurRadius: 1.0,
          color: Colors.black.withOpacity(0.3),
          offset: Offset(1, 1),
        ),
      ],
    );

    return GestureDetector(
      onTap: onFlip,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(right: 16),
        height: 240,
        child: TweenAnimationBuilder(
          tween: Tween<double>(
            begin: 0,
            end: (isFlipped || cvv.isNotEmpty) ? 180 : 0,
          ),
          duration: Duration(milliseconds: 500),
          builder: (context, double value, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY((value * pi) / 180),
              child: value < 90
                  ? _buildCardFront(
                      cardNumber: cardNumber,
                      cardHolderName: cardHolderName,
                      expiryDate: expiryDate,
                      masked: '**** **** **** ',
                      last4: cardNumber.isNotEmpty ? cardNumber.substring(cardNumber.length - min(4, cardNumber.length)) : '',
                      embossTextStyle: embossTextStyle,
                      themeColor: isSpecialMode ? specialThemeColor : Colors.red,
                    )
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _buildCardBack(
                        themeColor: isSpecialMode ? specialThemeColor : Colors.red,
                        cvv: cvv,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront({
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String masked,
    required String last4,
    required TextStyle embossTextStyle,
    required Color themeColor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isSpecialMode = themeNotifier.isSpecialModeActive;
    final specialThemeColor = themeNotifier.getThemeColor(themeNotifier.specialTheme);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.4),
            blurRadius: 25,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSpecialMode
                      ? [
                          specialThemeColor.shade900,
                          specialThemeColor.shade800,
                        ]
                      : [
                          Colors.red.shade900,
                          Colors.red.shade800,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Subtle background pattern
            Positioned(
              right: -100,
              bottom: -100,
              child: Icon(
                Icons.wallet_outlined,
                size: 250,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            // Glossy Shine Effect
            Positioned.fill(
              child: Transform.rotate(
                angle: 0.9,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.5],
                    ),
                  ),
                ),
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Image.asset(
                              Theme.of(context).brightness == Brightness.dark
                                  ? 'lib/assets/Images/app-icon-dark.png'
                                  : 'lib/assets/Images/app-icon-light.png',
                              width: 32,
                              height: 32,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Paradise Bank',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      // Contactless Icon
                      Transform.rotate(
                        angle: pi / 2,
                        child: Icon(Icons.wifi, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  // Chip and Card Number
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 55,
                        height: 40,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.yellow[600]?.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [Colors.yellow.shade600, Colors.yellow.shade800],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                            child: Icon(Icons.sd_card_rounded,
                                color: Colors.black.withOpacity(0.1), size: 30)),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                cardNumber.isEmpty 
                                  ? '**** **** **** ' 
                                  : cardNumber.replaceAllMapped(
                                      RegExp(r'.{4}'),
                                      (match) => '${match.group(0)} ',
                                    ).trim(),
                                style: embossTextStyle.copyWith(
                                  fontSize: 16,
                                  letterSpacing: 1.5,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  // Card Holder and Expiry
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.cardHolder,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10)),
                            Text(
                              cardHolderName.isEmpty ? 'CARD HOLDER' : cardHolderName.toUpperCase(),
                              style: embossTextStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.expires(expiryDate),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10)),
                            Text(
                              expiryDate.isEmpty ? 'MM/YY' : expiryDate,
                              style: embossTextStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Card Network Logo
                      _getCardNetworkLogo(cardNumber)
                    ],
                  ),
                ],
              ),
            ),
            // Mastercard logo
            Positioned(
              right: 20,
              bottom: 5,
              child: Container(
                width: 120,
                height: 82,
                alignment: Alignment.bottomRight,
                child: Image.asset(
                  'lib/assets/Images/mastercard-logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack({
    required Color themeColor,
    required String cvv,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isSpecialMode = themeNotifier.isSpecialModeActive;
    final specialThemeColor = themeNotifier.getThemeColor(themeNotifier.specialTheme);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.4),
            blurRadius: 25,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSpecialMode
                      ? [
                          specialThemeColor.shade900,
                          specialThemeColor.shade800,
                        ]
                      : [
                          Colors.red.shade900,
                          Colors.red.shade800,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Magnetic Strip
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Container(
                height: 50,
                color: Colors.black,
              ),
            ),
            // Signature Panel
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Container(
                height: 50,
                color: Colors.white,
                child: Center(
                  child: Text(
                    'Authorized Signature',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            // CVV Panel
            Positioned(
              top: 160,
              right: 20,
              child: Container(
                width: 60,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    cvv.isEmpty ? '***' : cvv,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            // Paradise Bank Logo and Text at bottom left
            Positioned(
              left: 20,
              bottom: 20,
              child: Row(
                children: [
                  Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'lib/assets/Images/app-icon-dark.png'
                        : 'lib/assets/Images/app-icon-light.png',
                    width: 24,
                    height: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Paradise Bank',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCardNetworkLogo(String cardNumber) {
    if (cardNumber.startsWith('4')) {
      return Text('VISA',
          style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic));
    } else if (cardNumber.startsWith('5')) {
      return Row(
        children: [
          Icon(Icons.circle, color: Colors.redAccent.withOpacity(0.9), size: 28),
          Transform.translate(
              offset: Offset(-16, 0),
              child: Icon(Icons.circle,
                  color: Colors.orangeAccent.withOpacity(0.9), size: 28)),
        ],
      );
    }
    return SizedBox.shrink();
  }
}

class AddCardForm extends StatefulWidget {
  final TextEditingController cardNumberController;
  final TextEditingController cardHolderController;
  final TextEditingController expiryDateController;
  final TextEditingController cvvController;
  final VoidCallback onSave;

  const AddCardForm({
    Key? key,
    required this.cardNumberController,
    required this.cardHolderController,
    required this.expiryDateController,
    required this.cvvController,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddCardForm> createState() => _AddCardFormState();
}

class _AddCardFormState extends State<AddCardForm> {
  bool _isCardFlipped = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Column(
      children: [
        _buildCardVisualization(
          cardNumber: widget.cardNumberController.text,
          cardHolderName: widget.cardHolderController.text,
          expiryDate: widget.expiryDateController.text,
          cvv: widget.cvvController.text,
          isFlipped: _isCardFlipped,
          onFlip: () {
            setState(() {
              _isCardFlipped = !_isCardFlipped;
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: widget.cardNumberController,
          decoration: InputDecoration(
            labelText: l10n.cardNumber,
            hintText: '1234 5678 9012 3456',
            prefixIcon: Icon(Icons.credit_card),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
          maxLength: 16,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: widget.cardHolderController,
          decoration: InputDecoration(
            labelText: l10n.cardHolderName,
            hintText: 'JOHN DOE',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.expiryDateController,
                decoration: InputDecoration(
                  labelText: l10n.expiryDate,
                  hintText: 'MM/YY',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: widget.expiryDateController.text.isNotEmpty &&
                          _isCardExpired(widget.expiryDateController.text)
                      ? l10n.cardIsExpired
                      : null,
                ),
                keyboardType: TextInputType.number,
                maxLength: 5,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryDateFormatter(),
                ],
                onChanged: (value) {
                  if (value.length == 2 && !value.contains('/')) {
                    widget.expiryDateController.text = '$value/';
                    widget.expiryDateController.selection = TextSelection.fromPosition(
                      TextPosition(offset: widget.expiryDateController.text.length),
                    );
                  }
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: widget.cvvController,
                decoration: InputDecoration(
                  labelText: l10n.cvv,
                  hintText: '123',
                  prefixIcon: Icon(Icons.security),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 3,
                obscureText: true,
                onChanged: (value) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: widget.onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: themeNotifier.isSpecialModeActive
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                : Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(
            l10n.save,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardVisualization({
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
    required bool isFlipped,
    required VoidCallback onFlip,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isSpecialMode = themeNotifier.isSpecialModeActive;
    final specialThemeColor = themeNotifier.getThemeColor(themeNotifier.specialTheme);

    final embossTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          blurRadius: 1.0,
          color: Colors.black.withOpacity(0.3),
          offset: Offset(1, 1),
        ),
      ],
    );

    return GestureDetector(
      onTap: onFlip,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(right: 16),
        height: 240,
        child: TweenAnimationBuilder(
          tween: Tween<double>(
            begin: 0,
            end: (isFlipped || cvv.isNotEmpty) ? 180 : 0,
          ),
          duration: Duration(milliseconds: 500),
          builder: (context, double value, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY((value * pi) / 180),
              child: value < 90
                  ? _buildCardFront(
                      cardNumber: cardNumber,
                      cardHolderName: cardHolderName,
                      expiryDate: expiryDate,
                      masked: '**** **** **** ',
                      last4: cardNumber.isNotEmpty ? cardNumber.substring(cardNumber.length - min(4, cardNumber.length)) : '',
                      embossTextStyle: embossTextStyle,
                      themeColor: isSpecialMode ? specialThemeColor : Colors.red,
                    )
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _buildCardBack(
                        themeColor: isSpecialMode ? specialThemeColor : Colors.red,
                        cvv: cvv,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront({
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String masked,
    required String last4,
    required TextStyle embossTextStyle,
    required Color themeColor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isSpecialMode = themeNotifier.isSpecialModeActive;
    final specialThemeColor = themeNotifier.getThemeColor(themeNotifier.specialTheme);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.4),
            blurRadius: 25,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSpecialMode
                      ? [
                          specialThemeColor.shade900,
                          specialThemeColor.shade800,
                        ]
                      : [
                          Colors.red.shade900,
                          Colors.red.shade800,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Subtle background pattern
            Positioned(
              right: -100,
              bottom: -100,
              child: Icon(
                Icons.wallet_outlined,
                size: 250,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            // Glossy Shine Effect
            Positioned.fill(
              child: Transform.rotate(
                angle: 0.9,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.5],
                    ),
                  ),
                ),
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Image.asset(
                              Theme.of(context).brightness == Brightness.dark
                                  ? 'lib/assets/Images/app-icon-dark.png'
                                  : 'lib/assets/Images/app-icon-light.png',
                              width: 32,
                              height: 32,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Paradise Bank',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      // Contactless Icon
                      Transform.rotate(
                        angle: pi / 2,
                        child: Icon(Icons.wifi, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  // Chip and Card Number
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 55,
                        height: 40,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.yellow[600]?.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [Colors.yellow.shade600, Colors.yellow.shade800],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                            child: Icon(Icons.sd_card_rounded,
                                color: Colors.black.withOpacity(0.1), size: 30)),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                cardNumber.isEmpty 
                                  ? '**** **** **** ' 
                                  : cardNumber.replaceAllMapped(
                                      RegExp(r'.{4}'),
                                      (match) => '${match.group(0)} ',
                                    ).trim(),
                                style: embossTextStyle.copyWith(
                                  fontSize: 16,
                                  letterSpacing: 1.5,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  // Card Holder and Expiry
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.cardHolder,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10)),
                            Text(
                              cardHolderName.isEmpty ? 'CARD HOLDER' : cardHolderName.toUpperCase(),
                              style: embossTextStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.expires(expiryDate),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10)),
                            Text(
                              expiryDate.isEmpty ? 'MM/YY' : expiryDate,
                              style: embossTextStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Card Network Logo
                      _getCardNetworkLogo(cardNumber)
                    ],
                  ),
                ],
              ),
            ),
            // Mastercard logo
            Positioned(
              right: 20,
              bottom: 5,
              child: Container(
                width: 120,
                height: 82,
                alignment: Alignment.bottomRight,
                child: Image.asset(
                  'lib/assets/Images/mastercard-logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack({
    required Color themeColor,
    required String cvv,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isSpecialMode = themeNotifier.isSpecialModeActive;
    final specialThemeColor = themeNotifier.getThemeColor(themeNotifier.specialTheme);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.4),
            blurRadius: 25,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSpecialMode
                      ? [
                          specialThemeColor.shade900,
                          specialThemeColor.shade800,
                        ]
                      : [
                          Colors.red.shade900,
                          Colors.red.shade800,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Magnetic Strip
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Container(
                height: 50,
                color: Colors.black,
              ),
            ),
            // Signature Panel
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Container(
                height: 50,
                color: Colors.white,
                child: Center(
                  child: Text(
                    'Authorized Signature',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            // CVV Panel
            Positioned(
              top: 160,
              right: 20,
              child: Container(
                width: 60,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    cvv.isEmpty ? '***' : cvv,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            // Paradise Bank Logo and Text at bottom left
            Positioned(
              left: 20,
              bottom: 20,
              child: Row(
                children: [
                  Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'lib/assets/Images/app-icon-dark.png'
                        : 'lib/assets/Images/app-icon-light.png',
                    width: 24,
                    height: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Paradise Bank',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCardNetworkLogo(String cardNumber) {
    if (cardNumber.startsWith('4')) {
      return Text('VISA',
          style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic));
    } else if (cardNumber.startsWith('5')) {
      return Row(
        children: [
          Icon(Icons.circle, color: Colors.redAccent.withOpacity(0.9), size: 28),
          Transform.translate(
              offset: Offset(-16, 0),
              child: Icon(Icons.circle,
                  color: Colors.orangeAccent.withOpacity(0.9), size: 28)),
        ],
      );
    }
    return SizedBox.shrink();
  }

  bool _isCardExpired(String expiryDate) {
    try {
      final parts = expiryDate.split('/');
      if (parts.length != 2) return true;

      final month = int.parse(parts[0]);
      final year = 2000 + int.parse(parts[1]);

      if (month < 1 || month > 12) return true;

      final now = DateTime.now();
      final cardExpiry = DateTime(year, month + 1, 0);

      return cardExpiry.isBefore(DateTime(now.year, now.month, 1));
    } catch (e) {
      return true;
    }
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2 && !text.contains('/')) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    String newText = buffer.toString();
    if (newText.length > 2) {
      final month = int.tryParse(newText.substring(0, 2)) ?? 0;
      if (month > 12) {
        newText = '12/${newText.substring(3)}';
      }
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
