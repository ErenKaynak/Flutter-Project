import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('wallet_transactions')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      setState(() {
        _transactions = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'amount': data['amount'] ?? 0.0,
            'type': data['type'] ?? '',
            'timestamp': data['timestamp']?.toDate() ?? DateTime.now(),
            'cashback': data['cashback'] ?? 0.0,
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching transactions: $e');
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
      await FirebaseFirestore.instance.collection('wallets').doc(user.uid).update({
        'balance': FieldValue.increment(amount),
        'last_transaction': FieldValue.serverTimestamp(),
      });

      // Record the transaction
      await FirebaseFirestore.instance.collection('wallet_transactions').add({
        'user_id': user.uid,
        'amount': amount,
        'type': 'deposit',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _fetchWalletBalance();
      _amountController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding balance: $e')),
      );
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
                      Text(
                        'Add Money',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₺',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ),
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

                      // Recent Transactions
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ..._transactions.map((transaction) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: transaction['type'] == 'deposit'
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                                child: Icon(
                                  transaction['type'] == 'deposit'
                                      ? Icons.add
                                      : Icons.shopping_bag,
                                  color: transaction['type'] == 'deposit'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              title: Text(
                                transaction['type'] == 'deposit'
                                    ? 'Added Money'
                                    : 'Purchase',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                _formatDate(transaction['timestamp']),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₺${transaction['amount'].abs().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: transaction['type'] == 'deposit'
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (transaction['cashback'] != null &&
                                      transaction['cashback'] > 0)
                                    Text(
                                      '+₺${transaction['cashback'].toStringAsFixed(2)} cashback',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )),
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
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₺',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
                  if (amount != null && amount > 0 && 
                      (_selectedCard != null || _showAddCard)) {
                    widget.onAddMoney(amount);
                    Navigator.pop(context);
                  }
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
          decoration: const InputDecoration(
            labelText: 'Card Number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cardHolderController,
          decoration: const InputDecoration(
            labelText: 'Card Holder Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'MM/YY',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cvvController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}