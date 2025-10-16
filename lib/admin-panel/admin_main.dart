import 'package:engineering_project/admin-panel/admin_banner_management.dart';
import 'package:engineering_project/admin-panel/admin_categories.dart';
import 'package:engineering_project/admin-panel/admin_wheel_management.dart';
import 'package:engineering_project/admin-panel/admin_discount.dart';
import 'package:engineering_project/admin-panel/admin_order_management.dart';
import 'package:engineering_project/admin-panel/admin_photoUploader.dart';
import 'package:engineering_project/admin-panel/admin_products.dart';
import 'package:engineering_project/admin-panel/admin_user.dart';
import 'package:engineering_project/admin-panel/admin_statistics.dart';
import 'package:engineering_project/admin-panel/admin_bug_reports.dart';
import 'package:engineering_project/admin-panel/admin_notification_management.dart';
import 'package:engineering_project/admin-panel/admin_homepage_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../pages/theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:rxdart/rxdart.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool isNotificationsExpanded = false;
  late final Stream<List<QueryDocumentSnapshot>> lowStockStream = FirebaseFirestore.instance
      .collection('products')
      .where('stock', isLessThanOrEqualTo: 3)
      .orderBy('stock', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs);
  late final Stream<List<QueryDocumentSnapshot>> refundRequestStream = FirebaseFirestore.instance
      .collection('orders')
      .where('status', isEqualTo: 'Refund Requested')
      .snapshots()
      .map((snapshot) => snapshot.docs);

  @override
  void initState() {
    super.initState();
  }

  Widget _buildLowStockList(List<QueryDocumentSnapshot> products) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;
    final l10n = AppLocalizations.of(context)!;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index].data() as Map<String, dynamic>;
        final int stock = product['stock'] ?? 0;
        final String productId = products[index].id;

        return ListTile(
          dense: true,
          leading: Icon(
            Icons.warning,
            color: themeColor,
          ),
          title: Text(
            product['name'] ?? 'Unnamed Product',
            style: TextStyle(
              color: stock == 0 ? themeColor : (isDark ? Colors.white : Colors.black87),
              fontWeight: stock == 0 ? FontWeight.bold : null,
            ),
          ),
          subtitle: Text(
            l10n.stockRemaining(stock),
            style: TextStyle(
              color: stock == 0 ? themeColor : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          onTap: () => _showUpdateStockDialog(context, productId, product['name'], stock),
        );
      },
    );
  }

  void _showUpdateStockDialog(BuildContext context, String productId, String productName, int currentStock) {
    final TextEditingController stockController = TextEditingController(text: currentStock.toString());
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.updateStock(productName)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.newStockAmount,
                hintText: l10n.enterNewStockAmount,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final newStock = int.tryParse(stockController.text);
              if (newStock != null && newStock >= 0) {
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .update({'stock': newStock});
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pleaseEnterValidNumber)),
                );
              }
            },
            child: Text(l10n.update),
          ),
        ],
      ),
    );
  }

  void _showAISettingsDialog(BuildContext context) {
    bool isAIEnabled = true;
    bool isFloatingButtonVisible = true;
    final l10n = AppLocalizations.of(context)!;

    FirebaseFirestore.instance
        .collection('settings')
        .doc('ai_settings')
        .get()
        .then((doc) {
      if (doc.exists) {
        isAIEnabled = doc.data()?['isEnabled'] ?? true;
        isFloatingButtonVisible = doc.data()?['showFloatingButton'] ?? false;
      }
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(l10n.assistantTommySettings),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: Text(l10n.enableAssistantTommy),
                      subtitle: Text(
                        isAIEnabled 
                            ? l10n.tommyAvailable 
                            : l10n.tommyDisabled
                      ),
                      value: isAIEnabled,
                      onChanged: (bool value) {
                        setState(() => isAIEnabled = value);
                        _updateAISettings(isEnabled: value);
                      },
                    ),
                    SwitchListTile(
                      title: Text(l10n.hideTommy),
                      subtitle: Text(
                        isFloatingButtonVisible 
                            ? l10n.allEyesOnTommy 
                            : l10n.tommyHiding
                      ),
                      value: !isFloatingButtonVisible,
                      onChanged: (bool value) {
                        setState(() => isFloatingButtonVisible = !value);
                        _updateAISettings(showFloatingButton: !value);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close),
                  ),
                ],
              );
            },
          );
        },
      );
    });
  }

  void _updateAISettings({bool? isEnabled, bool? showFloatingButton}) {
    final updateData = <String, dynamic>{
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    
    if (isEnabled != null) updateData['isEnabled'] = isEnabled;
    if (showFloatingButton != null) updateData['showFloatingButton'] = showFloatingButton;

    FirebaseFirestore.instance
        .collection('settings')
        .doc('ai_settings')
        .set(updateData, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.adminDashboard,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: isDark 
            ? (themeNotifier.isSpecialModeActive 
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade900 
                : Colors.red.shade900)
            : (themeNotifier.isSpecialModeActive 
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade700 
                : Colors.red.shade700),
        foregroundColor: Colors.white,
        elevation: isDark ? 0 : 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.adminControls,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color:
                    isBlackMode
                        ? Colors.white
                        : Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: isDark ? 1 : 2,
              color: isBlackMode ? Colors.black : Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color:
                      isBlackMode
                          ? Colors.grey.shade800
                          : isDark
                          ? Colors.grey.shade800
                          : Colors.transparent,
                  width: isDark || isBlackMode ? 1 : 0,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    isNotificationsExpanded = !isNotificationsExpanded;
                  });
                },
                child: StreamBuilder<List<List<QueryDocumentSnapshot>>>(
                  stream: Rx.combineLatest2(
                    lowStockStream,
                    refundRequestStream,
                    (List<QueryDocumentSnapshot> lowStock, List<QueryDocumentSnapshot> refunds) => [lowStock, refunds],
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return ListTile(
                        subtitle: Text(l10n.checkingStockLevels),
                      );
                    }

                    if (snapshot.hasError) {
                      return ListTile(
                        subtitle: Text("Error: \\${snapshot.error}"),
                      );
                    }

                    final lowStockProducts = snapshot.data?[0] ?? [];
                    final refundRequests = snapshot.data?[1] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  isBlackMode
                                      ? Colors.grey.shade700.withOpacity(0.2)
                                      : isDark
                                      ? Colors.orange.shade900.withOpacity(0.2)
                                      : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.notifications_active,
                              color:
                                  isBlackMode
                                      ? Colors.grey.shade400
                                      : isDark
                                      ? Colors.orange.shade400
                                      : Colors.orange.shade700,
                            ),
                          ),
                          title: Text(
                            l10n.lowStockAlerts,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            (lowStockProducts.isEmpty && refundRequests.isEmpty)
                                ? l10n.noLowStockProducts
                                : '${l10n.lowStockProductsCount(lowStockProducts.length)} / Refund Requests: ${refundRequests.length}',
                            style: TextStyle(
                              color: (lowStockProducts.isNotEmpty || refundRequests.isNotEmpty) ? Colors.orange : null,
                            ),
                          ),
                          trailing: Icon(
                            isNotificationsExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color:
                                isBlackMode
                                    ? Colors.white.withOpacity(0.5)
                                    : Theme.of(
                                      context,
                                    ).iconTheme.color?.withOpacity(0.5),
                          ),
                        ),
                        if (isNotificationsExpanded && (lowStockProducts.isNotEmpty || refundRequests.isNotEmpty)) ...[
                          if (lowStockProducts.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Text('Düşük Stoklu Ürünler', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            _buildLowStockList(lowStockProducts),
                          ],
                          if (refundRequests.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Text('Refund Requests', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: refundRequests.length,
                              itemBuilder: (context, index) {
                                final order = refundRequests[index].data() as Map<String, dynamic>;
                                final orderId = refundRequests[index].id;
                                return ListTile(
                                  dense: true,
                                  leading: Icon(Icons.money_off, color: Colors.orange),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Sipariş: $orderId',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.copy, size: 16.0),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: orderId));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Sipariş ID kopyalandı!')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  subtitle: Text('Müşteri: ' + (order['customerName'] ?? '-') + '\nTutar: ₺' + ((order['totalAmount'] ?? order['total'] ?? 0.0).toString())),
                                  onTap: () {
                                    // İade talebi detayına gitmek için buraya ekleme yapılabilir
                                  },
                                );
                              },
                            ),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildAdminCard(
              icon: Icons.people,
              title: l10n.userManagement,
              subtitle: l10n.viewAndManageUsers,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminUsersPage()),
              ),
            ),
            const SizedBox(height: 10),
            _buildAdminCard(
              icon: Icons.inventory_2,
              title: l10n.productManagement,
              subtitle: l10n.manageProducts,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminProducts()),
              ),
            ),
            const SizedBox(height: 10),
            _buildAdminCard(
              icon: Icons.shopping_cart,
              title: l10n.orderManagement,
              subtitle: l10n.viewAndProcessOrders,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderManagementPage()),
              ),
            ),
            const SizedBox(height: 10),
            _buildAdminCard(
              icon: Icons.account_balance_wallet_rounded,
              title: l10n.promoCodes,
              subtitle: l10n.createPromocodesAndDiscounts,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DiscountAdminPage()),
              ),
            ),
            const SizedBox(height: 10),
            _buildAdminCard(
              icon: Icons.analytics,
              title: l10n.salesStatistics,
              subtitle: l10n.viewSalesAnalytics,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminStatisticsPage()),
              ),
            ),
            const SizedBox(height: 10),

            _buildAdminCard(
              icon: Icons.bug_report,
              title: l10n.bugReports,
              subtitle: l10n.viewAndManageBugReports,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BugReportsPage()),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              l10n.settings,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    isBlackMode
                        ? Colors.white
                        : Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 10),
            _buildAdminCard(
              icon: Icons.settings,
              title: l10n.settings,
              subtitle: l10n.configureAppSettings,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.category),
                          title: Text(l10n.categories),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryManagementPage(),
                              ),
                              title: Text(
                                'Category Management',
                                style: TextStyle(
                                  color: isBlackMode ? Colors.white : null,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => CategoryManagementPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        ListTile(
                          leading: const Icon(Icons.add_photo_alternate_outlined),
                          title: Text(l10n.photoUploader),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PhotoUploaderPage(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.notifications),
                          title: Text(l10n.notificationManagement),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminNotificationManagement(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.featured_play_list),
                          title: Text(l10n.bannerManagement),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BannerManagementPage(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.casino),
                          title: Text(l10n.wheelManagement),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WheelManagementPage(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.sort),
                          title: Text('Homepage Layout'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomepageLayoutPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            _buildAdminCard(
              icon: Image.asset(
                'lib/assets/Images/Mascot/mascot-head.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
              title: l10n.assistantTommySettings,
              subtitle: l10n.configureTommyAvailability,
              onTap: () => _showAISettingsDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required dynamic icon, // Changed from IconData to dynamic
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    return Card(
      elevation: isDark ? 1 : 2,
      color: isDark ? Colors.grey.shade900 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isBlackMode
                  ? Colors.grey.shade800
                  : isDark
                  ? Colors.grey.shade800
                  : Colors.transparent,
          width: isDark || isBlackMode ? 1 : 0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark 
                ? themeColor.shade900.withOpacity(0.2) 
                : themeColor.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon is IconData 
              ? Icon(
                  icon,
                  color: isDark ? themeColor.shade400 : themeColor.shade700,
                )
              : icon, // Use the widget directly if it's not IconData
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: themeColor.withOpacity(0.5),
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}
