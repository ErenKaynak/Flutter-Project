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
  List<Map<String, dynamic>> _savedCards = [];
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
    await _fetchSavedCards();
  }

  Future<void> _fetchSavedCards() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final cardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .get();

      if (mounted) {
        setState(() {
          _savedCards = cardsSnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
      }
    } catch (e) {
      print('Error loading saved cards: $e');
    }
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
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: mediaQuery.size.height * 0.95,
                ),
                child: AddMoneyBottomSheet(
                  savedCards: savedCards,
                  onAddMoney: _addBalance,
                ),
              ),
            );
          },
        );
      },
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
    final themeColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myWallet,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        elevation: 0,
        backgroundColor: isDark ? themeColor.shade900 : themeColor.shade700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [themeColor.shade900, Colors.grey.shade900]
                : [themeColor.shade500, themeColor.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: themeNotifier.isBlackMode
                      ? Theme.of(context).colorScheme.secondary
                      : themeColor,
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
                              colors: [Color(0xFF232B5D), Color(0xFF181A20)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black26
                                    : themeColor.shade200.withOpacity(0.5),
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
                        if (_savedCards.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            l10n.myCards,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _savedCards.length,
                              itemBuilder: (context, index) {
                                return _buildCreditCardWidget(_savedCards[index]);
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _showAddMoneyDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? themeColor.shade900 : themeColor.shade400,
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
                        Divider(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          thickness: 1,
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
                                                              : themeColor.withOpacity(0.1),
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
                                                              : themeColor,
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
                                                                  : themeColor,
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

  Widget _buildCreditCardWidget(Map<String, dynamic> card) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final themeColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String cardNumber = card['cardNumber'] ?? '0000000000000000';
    String masked = '**** **** **** ';
    String last4 = cardNumber.substring(cardNumber.length - 4);
    String cardHolder = card['cardHolder']?.toUpperCase() ?? 'CARDHOLDER NAME';
    String expiryDate = card['expiryDate'] ?? 'MM/YY';

    // Emboss text style for a realistic raised effect
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

    return Container(
      width: 360,
      margin: const EdgeInsets.only(right: 16),
      height: 240,
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
                  colors: [Color(0xFF232B5D), Color(0xFF181A20)],
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
                      Icon(Icons.wifi, color: Colors.white, size: 32),
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
                            Text(
                              masked,
                              style: embossTextStyle.copyWith(
                                fontSize: 16,
                                letterSpacing: 1.5,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              last4,
                              style: embossTextStyle.copyWith(
                                fontSize: 16,
                                letterSpacing: 1.5,
                                fontFamily: 'monospace',
                                color: Colors.white,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CARD HOLDER',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10)),
                          Text(cardHolder, style: embossTextStyle),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EXPIRES',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10)),
                          Text(expiryDate, style: embossTextStyle),
                        ],
                      ),
                      // Card Network Logo
                      _getCardNetworkLogo(cardNumber)
                    ],
                  ),
                ],
              ),
            ),
            // Mastercard logo sağ alt köşe
            Positioned(
              right: 20,
              bottom: 20,
              child: Image.asset(
                'lib/assets/Images/mastercard-logo.png',
                width: 64,
                height: 44,
              ),
            ),
          ],
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

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.75,
      builder: (_, controller) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: controller,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
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
              SizedBox(height: 20),
            ],
          ),
        ),
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
  void initState() {
    super.initState();
    if (widget.savedCards.isNotEmpty) {
      _selectedCard = widget.savedCards.firstWhere(
        (card) => card['isDefault'] == true,
        orElse: () => widget.savedCards.first,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
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
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                final amountString = _amountController.text.replaceAll(',', '.');
                final amount = double.tryParse(amountString);
                
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.enterValidAmount),
                    ),
                  );
                  return;
                }

                if (amount > 10000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.maximumAmount),
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
        ],
      ),
    );
  }

  Widget _buildCardItem(Map<String, dynamic> card) {
    final isSelected = _selectedCard?['id'] == card['id'];
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCard = isSelected ? null : card;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? Colors.red.shade900 : Colors.red.shade700)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? (isDark ? Colors.red.shade900 : Colors.red.shade700)
                    : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.credit_card,
                  color: isSelected ? Colors.white : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '**** **** **** ${card['cardNumber'].substring(card['cardNumber'].length - 4)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : null,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card['cardHolder'],
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddCardForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.addNewCard,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
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
            prefixIcon: const Icon(Icons.credit_card, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorText: _cardNumberError,
            counterText: '',
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          ),
        ),
        const SizedBox(height: 8),
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
            prefixIcon: const Icon(Icons.person, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorText: _cardHolderController.text.isEmpty
                ? null
                : !_namePattern.hasMatch(_cardHolderController.text)
                    ? l10n.onlyLettersAllowed
                    : null,
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 8),
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
                  prefixIcon: const Icon(Icons.calendar_today, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: _expiryError,
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
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
                  prefixIcon: const Icon(Icons.security, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: _cvvError,
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
