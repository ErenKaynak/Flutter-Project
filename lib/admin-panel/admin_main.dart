import 'package:engineering_project/admin-panel/admin_categories.dart';
import 'package:engineering_project/admin-panel/admin_discount.dart';
import 'package:engineering_project/admin-panel/admin_order_management.dart';
import 'package:engineering_project/admin-panel/admin_products.dart';
import 'package:engineering_project/admin-panel/admin_user.dart';
import 'package:engineering_project/admin-panel/admin_statistics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/pages/theme_notifier.dart';

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
    lowStockProducts =
        FirebaseFirestore.instance
            .collection('products')
            .where('stock', isLessThanOrEqualTo: 3)
            .orderBy('stock', descending: false)
            .snapshots();
  }

  Widget _buildLowStockList(List<QueryDocumentSnapshot> products) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isBlackMode = themeNotifier.isBlackMode;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index].data() as Map<String, dynamic>;
        final int stock = product['stock'] ?? 0;

        return ListTile(
          dense: true,
          leading: Icon(
            Icons.warning,
            color: isBlackMode ? Colors.grey.shade400 : Colors.orange,
          ),
          title: Text(
            product['name'] ?? 'Unnamed Product',
            style: TextStyle(
              color:
                  isBlackMode
                      ? (stock == 0 ? Colors.red : Colors.white)
                      : (stock == 0 ? Colors.red : null),
              fontWeight: stock == 0 ? FontWeight.bold : null,
            ),
          ),
          subtitle: Text(
            'Stock remaining: $stock',
            style: TextStyle(
              color:
                  isBlackMode
                      ? (stock == 0 ? Colors.red : Colors.grey.shade400)
                      : (stock == 0 ? Colors.red : null),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isBlackMode = themeNotifier.isBlackMode;
    final isDark =
        Theme.of(context).brightness == Brightness.dark && !isBlackMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor:
            isBlackMode ? Colors.grey.shade500 : Theme.of(context).primaryColor,
        elevation: isDark ? 0 : 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Admin Controls",
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: lowStockProducts,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return ListTile(
                        subtitle: Text(
                          "Checking stock levels...",
                          style: TextStyle(
                            color: isBlackMode ? Colors.white : null,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return ListTile(
                        subtitle: Text(
                          "Error: ${snapshot.error}",
                          style: TextStyle(
                            color: isBlackMode ? Colors.white : null,
                          ),
                        ),
                      );
                    }

                    final products = snapshot.data?.docs ?? [];

                    return Column(
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
                            "Low Stock Alerts",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isBlackMode ? Colors.white : null,
                            ),
                          ),
                          subtitle: Text(
                            products.isEmpty
                                ? "No products low on stock"
                                : "${products.length} product${products.length == 1 ? '' : 's'} low on stock",
                            style: TextStyle(
                              color:
                                  isBlackMode
                                      ? (products.isNotEmpty
                                          ? Colors.grey.shade400
                                          : Colors.white)
                                      : products.isNotEmpty
                                      ? Colors.orange
                                      : null,
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
              title: "User Management",
              subtitle: "View and manage users",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminUsersPage(),
                    ),
                  ),
            ),
            const SizedBox(height: 10),
            _buildAdminCard(
              icon: Icons.inventory_2,
              title: "Product Management",
              subtitle: "Add, edit or remove products",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminProducts(),
                    ),
                  ),
            ),
            const SizedBox(height: 10),
            _buildAdminCard(
              icon: Icons.shopping_cart,
              title: "Order Management",
              subtitle: "View and process orders",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderManagementPage(),
                    ),
                  ),
            ),
            const SizedBox(height: 10),
            _buildAdminCard(
              icon: Icons.account_balance_wallet_rounded,
              title: "Promo Codes",
              subtitle: "Create Promocodes and Discounts",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DiscountAdminPage(),
                    ),
                  ),
            ),
            const SizedBox(height: 10),
            _buildAdminCard(
              icon: Icons.analytics,
              title: "Sales Statistics",
              subtitle: "View sales analytics and charts",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminStatisticsPage(),
                    ),
                  ),
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 20),
            Text(
              "Admin Settings",
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
              title: "App Settings",
              subtitle: "Configure application settings",
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder:
                      (context) => Container(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.category,
                                color:
                                    isBlackMode ? Colors.grey.shade400 : null,
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
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isBlackMode = themeNotifier.isBlackMode;
    final isDark =
        Theme.of(context).brightness == Brightness.dark && !isBlackMode;

    return Card(
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isBlackMode
                    ? Colors.grey.shade700.withOpacity(0.2)
                    : isDark
                    ? Colors.red.shade900.withOpacity(0.2)
                    : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color:
                isBlackMode
                    ? Colors.grey.shade500
                    : isDark
                    ? Colors.red.shade400
                    : Colors.red.shade700,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color:
                isBlackMode
                    ? Colors.white
                    : Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color:
                isBlackMode
                    ? Colors.grey.shade400
                    : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color:
              isBlackMode
                  ? Colors.white.withOpacity(0.5)
                  : Theme.of(context).iconTheme.color?.withOpacity(0.5),
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}
