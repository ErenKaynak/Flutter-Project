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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool isNotificationsExpanded = false;
  late Stream<QuerySnapshot> lowStockProducts;

  @override
  void initState() {
    super.initState();
    // Optimized query with ordering and field selection
    lowStockProducts = FirebaseFirestore.instance
        .collection('products')
        .where('stock', isLessThanOrEqualTo: 3)
        .orderBy('stock', descending: false)
        .snapshots();
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
        title: Text(l10n.adminDashboard),
        backgroundColor: isDark ? Colors.red.shade900 : themeColor,
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
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: isDark ? 1 : 2,
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.transparent,
                  width: isDark ? 1 : 0,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    isNotificationsExpanded = !isNotificationsExpanded;
                  });
                },
                child: StreamBuilder<QuerySnapshot>(
                  stream: lowStockProducts,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return ListTile(
                        subtitle: Text(l10n.checkingStockLevels),
                      );
                    }

                    if (snapshot.hasError) {
                      return ListTile(
                        subtitle: Text("Error: ${snapshot.error}"),
                      );
                    }

                    final products = snapshot.data?.docs ?? [];

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.orange.shade900.withOpacity(0.2) : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.notifications_active,
                              color: isDark ? Colors.orange.shade400 : Colors.orange.shade700,
                            ),
                          ),
                          title: Text(
                            l10n.lowStockAlerts,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            products.isEmpty
                                ? l10n.noLowStockProducts
                                : l10n.lowStockProductsCount(products.length),
                            style: TextStyle(
                              color: products.isNotEmpty ? Colors.orange : null,
                            ),
                          ),
                          trailing: Icon(
                            isNotificationsExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                          ),
                        ),
                        if (isNotificationsExpanded && products.isNotEmpty)
                          _buildLowStockList(products),
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
                color: Theme.of(context).textTheme.titleLarge?.color,
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
                            );
                          },
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
          color: isDark ? Colors.grey.shade800 : Colors.transparent,
          width: isDark ? 1 : 0,
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