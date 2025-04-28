import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double _balance = 0.0;
  final _amountController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('wallet_transactions')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _transactions = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'amount': (data['amount'] ?? 0.0).toDouble(),
            'type': data['type'] ?? '',
            'timestamp': data['timestamp']?.toDate() ?? DateTime.now(),
            'cashback': (data['cashback'] ?? 0.0).toDouble(),
            'method': data['method'] ?? '',
            'status': data['status'] ?? 'completed',
            'reference': data['reference'],
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        _transactions = [];
        _isLoading = false;
      });
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

      if (!doc.exists) {
        // Create wallet if it doesn't exist
        await FirebaseFirestore.instance.collection('wallets').doc(user.uid).set({
          'balance': 0.0,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        setState(() {
          _balance = (doc.data()?['balance'] ?? 0.0).toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching wallet: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addBalance(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Start a batch write to ensure both operations complete
      final batch = FirebaseFirestore.instance.batch();
      
      // Update wallet balance
      final walletRef = FirebaseFirestore.instance.collection('wallets').doc(user.uid);
      batch.update(walletRef, {
        'balance': FieldValue.increment(amount),
        'last_transaction': FieldValue.serverTimestamp(),
      });

      // Create transaction record
      final transactionRef = FirebaseFirestore.instance.collection('wallet_transactions').doc();
      batch.set(transactionRef, {
        'user_id': user.uid,
        'amount': amount,
        'type': 'deposit',
        'timestamp': FieldValue.serverTimestamp(),
        'method': 'card_deposit',
        'status': 'completed',
      });

      // Commit both operations
      await batch.commit();

      // Refresh wallet balance and transactions
      await _fetchWalletBalance();
      await _fetchTransactions();
      
      _amountController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Money added successfully')),
        );
      }
    } catch (e) {
      print('Error adding balance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding balance: $e')),
        );
      }
    }
  }

  Future<void> _showAddMoneyDialog() async {
    List<Map<String, dynamic>> savedCards = [];
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final cardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .get();

      savedCards = cardsSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('Error loading cards: $e');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddMoneyBottomSheet(
        savedCards: savedCards,
        onAddMoney: _addBalance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchWalletBalance();
                await _fetchTransactions();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [Colors.red.shade900, Colors.grey.shade900]
                                : [Colors.red.shade500, Colors.red.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black26
                                  : Colors.red.shade200.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Balance',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₺${_balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '1% Cashback on all purchases',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Add Money Section
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _showAddMoneyDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Add Money',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Transactions Section
                      Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Transaction History',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  Text(
                                    '${_transactions.length} transactions',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_transactions.isEmpty) ...[
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.receipt_long,
                                        size: 48,
                                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No transactions yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Your transaction history will appear here',
                                      style: TextStyle(
                                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _transactions.length,
                                itemBuilder: (context, index) {
                                  final transaction = _transactions[index];
                                  final bool isDeposit = transaction['type'] == 'deposit';
                                  
                                  return Card(
                                    elevation: 2,
                                    margin: EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        // Show transaction details in a modal bottom sheet
                                        showModalBottomSheet(
                                          context: context,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                          ),
                                          builder: (context) => _buildTransactionDetails(transaction),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            // Transaction Icon
                                            Container(
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isDeposit
                                                    ? Colors.green.withOpacity(0.1)
                                                    : Colors.red.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isDeposit ? Icons.add : Icons.shopping_bag,
                                                color: isDeposit ? Colors.green : Colors.red,
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            // Transaction Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    isDeposit ? 'Money Added' : (transaction['description'] ?? 'Purchase'),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    _formatDate(transaction['timestamp']),
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  if (transaction['reference'] != null)
                                                    Text(
                                                      transaction['reference'],
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            // Amount
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${isDeposit ? '+' : '-'}₺${transaction['amount'].abs().toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    color: isDeposit ? Colors.green : Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (transaction['cashback'] != null &&
                                                    transaction['cashback'] > 0)
                                                  Text(
                                                    '+₺${transaction['cashback'].toStringAsFixed(2)} cashback',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTransactionDetails(Map<String, dynamic> transaction) {
    final bool isDeposit = transaction['type'] == 'deposit';
    
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 20),
          _detailRow('Type', isDeposit ? 'Deposit' : 'Purchase'),
          _detailRow('Amount', '₺${transaction['amount'].abs().toStringAsFixed(2)}'),
          if (transaction['cashback'] != null && transaction['cashback'] > 0)
            _detailRow('Cashback', '₺${transaction['cashback'].toStringAsFixed(2)}'),
          _detailRow('Date', _formatDate(transaction['timestamp'])),
          _detailRow('Status', transaction['status']?.toUpperCase() ?? 'COMPLETED'),
          _detailRow('Method', transaction['method']?.replaceAll('_', ' ').toUpperCase() ?? 'WALLET'),
          if (transaction['reference'] != null)
            _detailRow('Reference', transaction['reference']),
          if (transaction['description'] != null)
            _detailRow('Description', transaction['description']),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class AddMoneyBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> savedCards;
  final Function(double) onAddMoney;

  const AddMoneyBottomSheet({
    Key? key,
    required this.savedCards,
    required this.onAddMoney,
  }) : super(key: key);

  @override
  State<AddMoneyBottomSheet> createState() => _AddMoneyBottomSheetState();
}

class _AddMoneyBottomSheetState extends State<AddMoneyBottomSheet> {
  Map<String, dynamic>? _selectedCard;
  final _amountController = TextEditingController();
  bool _showAddCard = false;

  // Add card form controllers
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String? _cardNumberError;
  String? _expiryError;
  String? _cvvError;

  final RegExp _namePattern = RegExp(r'^[a-zA-Z\s]*$');
  final RegExp _numberPattern = RegExp(r'^\d+$');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Money to Wallet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₺',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '0.00',
                errorText: _validateAmount(_amountController.text),
              ),
              onChanged: (value) {
                setState(() {}); // Trigger rebuild to update error message
              },
            ),
            const SizedBox(height: 20),
            if (!_showAddCard && widget.savedCards.isNotEmpty) ...[
              Text(
                'Select Card',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ...widget.savedCards.map((card) => _buildCardItem(card)),
            ],
            if (_showAddCard) ...[
              _buildAddCardForm(),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _showAddCard = !_showAddCard;
                });
              },
              child: Text(_showAddCard ? 'Use Saved Card' : 'Add New Card'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(_amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid amount')),
                    );
                    return;
                  }
                  
                  if (_showAddCard) {
                    // Validate new card inputs
                    if (_cardNumberError != null || 
                        _expiryError != null || 
                        _cvvError != null ||
                        _cardNumberController.text.isEmpty ||
                        _cardHolderController.text.isEmpty ||
                        _expiryController.text.isEmpty ||
                        _cvvController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all card details correctly')),
                      );
                      return;
                    }
                  } else if (_selectedCard == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a card')),
                    );
                    return;
                  }
                  
                  widget.onAddMoney(amount);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add Money'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(Map<String, dynamic> card) {
    final isSelected = _selectedCard?['id'] == card['id'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCard = isSelected ? null : card;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.red.shade400 : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.credit_card, 
                 color: isSelected ? Colors.red.shade400 : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '**** **** **** ${card['cardNumber'].substring(card['cardNumber'].length - 4)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    card['cardHolder'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.red.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add New Card',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          maxLength: 16,
          onChanged: (value) {
            setState(() {
              if (value.length != 16) {
                _cardNumberError = 'Card number must be 16 digits';
              } else if (!RegExp(r'^[0-9]{16}$').hasMatch(value)) {
                _cardNumberError = 'Invalid card number';
              } else {
                _cardNumberError = null;
              }
            });
          },
          decoration: InputDecoration(
            labelText: 'Card Number',
            border: const OutlineInputBorder(),
            errorText: _cardNumberError,
            counterText: '', // Hides the built-in counter
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cardHolderController,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(_namePattern),
            TextInputFormatter.withFunction((oldValue, newValue) {
              // Convert to uppercase
              return TextEditingValue(
                text: newValue.text.toUpperCase(),
                selection: newValue.selection,
              );
            }),
          ],
          decoration: InputDecoration(
            labelText: 'Card Holder Name',
            border: const OutlineInputBorder(),
            errorText: _cardHolderController.text.isEmpty ? null : 
                      !_namePattern.hasMatch(_cardHolderController.text) ? 
                      'Only letters allowed' : null,
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiryController,
                keyboardType: TextInputType.number,
                maxLength: 5,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryDateFormatter(),
                ],
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                      _expiryError = 'Required';
                    } else if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(value)) {
                      _expiryError = 'Use MM/YY format';
                    } else {
                      final parts = value.split('/');
                      final month = int.parse(parts[0]);
                      final year = int.parse('20${parts[1]}');
                      final expiry = DateTime(year, month);
                      if (expiry.isBefore(DateTime.now())) {
                        _expiryError = 'Card expired';
                      } else {
                        _expiryError = null;
                      }
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: 'MM/YY',
                  border: const OutlineInputBorder(),
                  errorText: _expiryError,
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cvvController,
                keyboardType: TextInputType.number,
                maxLength: 3,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                onChanged: (value) {
                  setState(() {
                    if (!_numberPattern.hasMatch(value) || value.length != 3) {
                      _cvvError = 'Invalid CVV';
                    } else {
                      _cvvError = null;
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: 'CVV',
                  border: const OutlineInputBorder(),
                  errorText: _cvvError,
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _validateAmount(String value) {
    if (value.isEmpty) return null;
    
    try {
      final amount = double.parse(value);
      if (amount <= 0) {
        return 'Amount must be greater than 0';
      }
      if (amount > 10000) {
        return 'Maximum amount is ₺10,000';
      }
    } catch (e) {
      return 'Invalid amount';
    }
    return null;
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}