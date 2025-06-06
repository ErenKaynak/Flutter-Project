import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/assets/components/wallet_auth_service.dart';
import 'package:engineering_project/pages/wallet_pin_setup.dart';
import 'theme_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:engineering_project/pages/pin_entry_screen.dart';
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double _balance = 0.0;
  final _amountController = TextEditingController();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  List<Map<String, dynamic>> _transactions = [];
  final _walletAuthService = WalletAuthService();
  final _pinController = TextEditingController();
  String? _error;
  bool _authChecked = false;
  bool _authFailed = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    if (_authChecked) return;
    _authChecked = true;
    print('[WalletPage] Starting authentication check...');
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isPinSet = await _walletAuthService.isPinSet();
      print('[WalletPage] isPinSet: $isPinSet');
      
      if (!isPinSet) {
        print('[WalletPage] Navigating to WalletPinSetup...');
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WalletPinSetup()),
        );
        print('[WalletPage] WalletPinSetup result: $result');
        if (result == true) {
          setState(() {
            _isAuthenticated = true;
            _authFailed = false;
          });
          _loadWalletData();
        } else {
          print('[WalletPage] PIN setup cancelled. Showing fallback UI.');
          if (mounted) setState(() { _authFailed = true; });
        }
      } else {
        if (kIsWeb) {
          print('[WalletPage] Running on web, showing web PIN dialog...');
          await _showWebPinDialog();
        } else {
          print('[WalletPage] Running on mobile, showing PinEntryScreen...');
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PinEntryScreen(
                pinLength: 4,
                title: 'Enter PIN',
                subtitle: 'Unlock your wallet',
                showBiometrics: true,
                confirmMode: false,
                onPinEntered: (pin) async {
                  final isValid = await _walletAuthService.verifyPin(pin);
                  print('[WalletPage] PinEntryScreen onPinEntered: $isValid');
                  return isValid;
                },
              ),
            ),
          );
          print('[WalletPage] PinEntryScreen result: $result');
          if (result == true) {
            setState(() {
              _isAuthenticated = true;
              _authFailed = false;
            });
            _loadWalletData();
          } else {
            print('[WalletPage] PIN entry cancelled. Showing fallback UI.');
            if (mounted) setState(() { _authFailed = true; });
          }
        }
      }
    });
  }

  Future<void> _showWebPinDialog() async {
    final TextEditingController pinController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Enter your 4-digit PIN',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final isValid = await _walletAuthService.verifyPin(pinController.text);
                Navigator.of(context).pop(isValid);
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        _isAuthenticated = true;
        _authFailed = false;
      });
      _loadWalletData();
    } else {
      setState(() {
        _authFailed = true;
      });
    }
  }

  Future<void> _loadWalletData() async {
    await _fetchWalletBalance();
    await _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('wallet_transactions')
              .where('user_id', isEqualTo: user.uid)
              .orderBy('timestamp', descending: true)
              .get();

      setState(() {
        _transactions =
            snapshot.docs.map((doc) {
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
      final doc =
          await FirebaseFirestore.instance
              .collection('wallets')
              .doc(user.uid)
              .get();

      if (!doc.exists) {
        await FirebaseFirestore.instance
            .collection('wallets')
            .doc(user.uid)
            .set({'balance': 0.0, 'created_at': FieldValue.serverTimestamp()});
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
      final batch = FirebaseFirestore.instance.batch();

      final walletRef = FirebaseFirestore.instance
          .collection('wallets')
          .doc(user.uid);
      batch.update(walletRef, {
        'balance': FieldValue.increment(amount),
        'last_transaction': FieldValue.serverTimestamp(),
      });

      final transactionRef =
          FirebaseFirestore.instance.collection('wallet_transactions').doc();
      batch.set(transactionRef, {
        'user_id': user.uid,
        'amount': amount,
        'type': 'deposit',
        'timestamp': FieldValue.serverTimestamp(),
        'method': 'card_deposit',
        'status': 'completed',
      });

      await batch.commit();

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding balance: $e')));
      }
    }
  }

  Future<void> _showAddMoneyDialog() async {
    List<Map<String, dynamic>> savedCards = [];
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final cardsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cards')
              .get();

      savedCards =
          cardsSnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
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
      builder:
          (context) => AddMoneyBottomSheet(
            savedCards: savedCards,
            onAddMoney: _addBalance,
          ),
    );
  }

  String _formatPrice(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _formatPriceWithSign(double amount, bool isPositive) {
    final formatted = _formatPrice(amount.abs());
    return isPositive ? '+$formatted' : '-$formatted';
  }

  @override
  Widget build(BuildContext context) {
    print('[WalletPage] build: _isAuthenticated=$_isAuthenticated, _authFailed=$_authFailed, _isLoading=$_isLoading');
    if (_authFailed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wallet')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Authentication cancelled or failed.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }
    if (!_isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;
    final specialColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myWallet,
          style: TextStyle(
            color: isDark ? Colors.white : Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        elevation: 0,
        backgroundColor: isDark ? Colors.red.shade900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    themeNotifier.isSpecialModeActive
                        ? (specialColor?.shade900 ?? Colors.red.shade900)
                        : Colors.red.shade900,
                    Colors.grey.shade900,
                  ]
                : [
                    themeNotifier.isSpecialModeActive
                        ? (specialColor?.shade50 ?? Colors.red.shade50)
                        : Colors.red.shade50,
                    Colors.white,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: themeNotifier.isSpecialModeActive
                      ? specialColor
                      : (themeNotifier.isBlackMode
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.red),
                ),
              )
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
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      themeNotifier.isSpecialModeActive
                                          ? (specialColor?.shade900 ?? Colors.red.shade900)
                                          : Colors.red.shade900,
                                      Colors.grey.shade900,
                                    ]
                                  : [
                                      themeNotifier.isSpecialModeActive
                                          ? (specialColor?.shade500 ?? Colors.red.shade500)
                                          : Colors.red.shade500,
                                      themeNotifier.isSpecialModeActive
                                          ? (specialColor?.shade100 ?? Colors.red.shade100)
                                          : Colors.red.shade100,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black26
                                    : (themeNotifier.isSpecialModeActive
                                        ? (specialColor?.shade200.withOpacity(0.5) ?? Colors.red.shade200.withOpacity(0.5))
                                        : Colors.red.shade200.withOpacity(0.5)),
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
                                l10n.currentBalance,
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatPrice(_balance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                l10n.cashbackInfo,
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _showAddMoneyDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeNotifier.isSpecialModeActive
                                  ? specialColor
                                  : (isDark
                                      ? Colors.red.shade900
                                      : Colors.red.shade400),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              l10n.addMoney,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade800 : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black26 : Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.transactionHistory,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    l10n.transactionsCount(_transactions.length),
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_transactions.isEmpty) ...[
                                Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
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
                                        l10n.noTransactions,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.transactionsWillAppear,
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
                                    final String type = transaction['type'] ?? '';
                                    final bool isDeposit = type == 'deposit';
                                    final bool isRefund = type == 'refund';
                                    final bool isCashbackReversal = type == 'cashback_reversal';

                                    return Card(
                                      elevation: 2,
                                      margin: EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      color: isDark ? Colors.grey.shade700 : Colors.white,
                                      child: InkWell(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                            ),
                                            builder: (context) => _buildTransactionDetails(transaction),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isDeposit
                                                      ? Colors.green.withOpacity(0.1)
                                                      : isRefund
                                                          ? Colors.blue.withOpacity(0.1)
                                                          : isCashbackReversal
                                                              ? Colors.orange.withOpacity(0.1)
                                                              : (themeNotifier.isSpecialModeActive
                                                                  ? specialColor?.withOpacity(0.1) ?? Colors.red.withOpacity(0.1)
                                                                  : Colors.red.withOpacity(0.1)),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  isDeposit
                                                      ? Icons.add
                                                      : isRefund
                                                          ? Icons.reply
                                                          : isCashbackReversal
                                                              ? Icons.undo
                                                              : Icons.shopping_bag,
                                                  color: isDeposit
                                                      ? Colors.green
                                                      : isRefund
                                                          ? Colors.blue
                                                          : isCashbackReversal
                                                              ? Colors.orange
                                                              : (themeNotifier.isSpecialModeActive
                                                                  ? specialColor
                                                                  : Colors.red),
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      isDeposit
                                                          ? l10n.deposit
                                                          : isRefund
                                                              ? l10n.refunded
                                                              : isCashbackReversal
                                                                  ? 'Cashback Reversal'
                                                                  : (transaction['description'] ?? l10n.purchase),
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        color: isDark ? Colors.white : Colors.black87,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      _formatDate(transaction['timestamp']),
                                                      style: TextStyle(
                                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    isDeposit
                                                        ? _formatPriceWithSign(transaction['amount'], true)
                                                        : isRefund
                                                            ? _formatPriceWithSign(transaction['amount'], true)
                                                            : isCashbackReversal
                                                                ? _formatPriceWithSign(transaction['amount'], false)
                                                                : _formatPriceWithSign(transaction['amount'], false),
                                                    style: TextStyle(
                                                      color: isDeposit
                                                          ? Colors.green
                                                          : isRefund
                                                              ? Colors.blue
                                                              : isCashbackReversal
                                                                  ? Colors.orange
                                                                  : (themeNotifier.isSpecialModeActive
                                                                      ? specialColor
                                                                      : Colors.red),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  if (transaction['cashback'] != null && transaction['cashback'] > 0)
                                                    Text(
                                                      _formatPriceWithSign(transaction['cashback'], true) + ' cashback',
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
              ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTransactionDetails(Map<String, dynamic> transaction) {
    final String type = transaction['type'] ?? '';
    final bool isDeposit = type == 'deposit';
    final bool isRefund = type == 'refund';
    final bool isCashbackReversal = type == 'cashback_reversal';
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.transactionDetails,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 20),
          _detailRow(l10n.type, isDeposit ? l10n.deposit : isRefund ? l10n.refunded : isCashbackReversal ? 'Cashback Reversal' : l10n.purchase),
          _detailRow(
            l10n.amount,
            isDeposit
                ? _formatPriceWithSign(transaction['amount'], true)
                : isRefund
                    ? _formatPriceWithSign(transaction['amount'], true)
                    : isCashbackReversal
                        ? _formatPriceWithSign(transaction['amount'], false)
                        : _formatPriceWithSign(transaction['amount'], false),
          ),
          if (transaction['cashback'] != null && transaction['cashback'] > 0)
            _detailRow(
              'Cashback',
              _formatPrice(transaction['cashback']),
            ),
          _detailRow(l10n.date, _formatDate(transaction['timestamp'])),
          _detailRow(
            l10n.status,
            transaction['status']?.toUpperCase() ?? 'COMPLETED',
          ),
          _detailRow(
            l10n.method,
            transaction['method']?.replaceAll('_', ' ').toUpperCase() ?? 'WALLET',
          ),
          if (transaction['reference'] != null)
            _detailRow(l10n.reference, transaction['reference']),
          if ((isRefund || isCashbackReversal) && transaction['description'] != null)
            _detailRow(l10n.description, transaction['description']),
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
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

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
              l10n.addMoneyToWallet,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: l10n.amount,
                prefixText: '₺',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '0.00',
                errorText: _validateAmount(_amountController.text, l10n),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            if (!_showAddCard && widget.savedCards.isNotEmpty) ...[
              Text(
                l10n.selectCard,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ...widget.savedCards.map((card) => _buildCardItem(card)),
            ],
            if (_showAddCard) ...[_buildAddCardForm()],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _showAddCard = !_showAddCard;
                });
              },
              child: Text(_showAddCard ? l10n.useCard : l10n.addNewCard),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(_amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.enterValidAmount),
                      ),
                    );
                    return;
                  }

                  if (_showAddCard) {
                    if (_cardNumberError != null ||
                        _expiryError != null ||
                        _cvvError != null ||
                        _cardNumberController.text.isEmpty ||
                        _cardHolderController.text.isEmpty ||
                        _expiryController.text.isEmpty ||
                        _cvvController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.fillCardDetails),
                        ),
                      );
                      return;
                    }

                    await _saveNewCard();
                  } else if (_selectedCard == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.pleaseSelectCard)),
                    );
                    return;
                  }

                  widget.onAddMoney(amount);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeNotifier.isSpecialModeActive
                      ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade400
                      : Colors.red.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.addMoney),
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);

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
            color: isSelected
                ? (themeNotifier.isSpecialModeActive
                    ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade400
                    : Colors.red.shade400)
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.credit_card,
              color: isSelected
                  ? (themeNotifier.isSpecialModeActive
                      ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade400
                      : Colors.red.shade400)
                  : Colors.grey,
            ),
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
              Icon(
                Icons.check_circle,
                color: themeNotifier.isSpecialModeActive
                    ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade400
                    : Colors.red.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCardForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.addNewCard, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          maxLength: 16,
          onChanged: (value) {
            setState(() {
              if (value.length != 16) {
                _cardNumberError = l10n.cardNumberError;
              } else if (!RegExp(r'^[0-9]{16}$').hasMatch(value)) {
                _cardNumberError = l10n.invalidCardNumber;
              } else {
                _cardNumberError = null;
              }
            });
          },
          decoration: InputDecoration(
            labelText: l10n.cardNumber,
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorText: _cardNumberError,
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cardHolderController,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(_namePattern),
            TextInputFormatter.withFunction((oldValue, newValue) {
              return TextEditingValue(
                text: newValue.text.toUpperCase(),
                selection: newValue.selection,
              );
            }),
          ],
          decoration: InputDecoration(
            labelText: l10n.cardHolderName,
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorText: _cardHolderController.text.isEmpty
                ? null
                : !_namePattern.hasMatch(_cardHolderController.text)
                    ? l10n.onlyLettersAllowed
                    : null,
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
                      _expiryError = l10n.required;
                    } else if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(value)) {
                      _expiryError = l10n.useMMYYFormat;
                    } else {
                      final parts = value.split('/');
                      final month = int.parse(parts[0]);
                      final year = int.parse('20${parts[1]}');
                      final expiry = DateTime(year, month);
                      if (expiry.isBefore(DateTime.now())) {
                        _expiryError = l10n.cardExpired;
                      } else {
                        _expiryError = null;
                      }
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: 'MM/YY',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                onChanged: (value) {
                  setState(() {
                    if (!_numberPattern.hasMatch(value) || value.length != 3) {
                      _cvvError = l10n.invalidCVV;
                    } else {
                      _cvvError = null;
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: 'CVV',
                  prefixIcon: const Icon(Icons.security),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

  String? _validateAmount(String value, AppLocalizations l10n) {
    if (value.isEmpty) return null;

    try {
      final amount = double.parse(value);
      if (amount <= 0) {
        return l10n.amountMustBeGreater;
      }
      if (amount > 10000) {
        return l10n.maximumAmount;
      }
    } catch (e) {
      return l10n.invalidAmount;
    }
    return null;
  }

  Future<void> _saveNewCard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final cardRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .doc();

      await cardRef.set({
        'cardNumber': _cardNumberController.text,
        'cardHolder': _cardHolderController.text.toUpperCase(),
        'expiryDate': _expiryController.text,
        'cvv': _cvvController.text,
        'isDefault': widget.savedCards.isEmpty,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _cardNumberController.clear();
      _cardHolderController.clear();
      _expiryController.clear();
      _cvvController.clear();

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cardSaved)),
      );

      setState(() {
        _showAddCard = false;
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorSavingCard(e.toString()))),
      );
    }
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
