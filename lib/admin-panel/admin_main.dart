import 'package:engineering_project/admin-panel/admin_categories.dart';
import 'package:engineering_project/admin-panel/admin_discount.dart';
import 'package:engineering_project/admin-panel/admin_notification.dart';
import 'package:engineering_project/admin-panel/admin_order_management.dart';
import 'package:engineering_project/admin-panel/admin_photoUploader.dart';
import 'package:engineering_project/admin-panel/admin_products.dart';
import 'package:engineering_project/admin-panel/admin_user.dart';
import 'package:engineering_project/admin-panel/admin_statistics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
          leading: const Icon(Icons.warning, color: Colors.orange),
          title: Text(
            product['name'] ?? 'Unnamed Product',
            style: TextStyle(
              color: stock == 0 ? Colors.red : null,
              fontWeight: stock == 0 ? FontWeight.bold : null,
            ),
          ),
          subtitle: Text(
            'Stock remaining: $stock',
            style: TextStyle(
              color: stock == 0 ? Colors.red : null,
            ),
          ),
          onTap: () => _showUpdateStockDialog(context, productId, product['name'], stock),
        );
      },
    );
  }

  void _showUpdateStockDialog(BuildContext context, String productId, String productName, int currentStock) {
    final TextEditingController stockController = TextEditingController(text: currentStock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock for $productName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Stock Amount',
                hintText: 'Enter new stock amount',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
                  const SnackBar(content: Text('Please enter a valid number')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAISettingsDialog(BuildContext context) {
    bool isAIEnabled = true;
    bool isFloatingButtonVisible = true; // Changed default to true

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
                title: const Text('Assistant Tommy\'s Settings'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Assistant Tommy'),
                      subtitle: Text(
                        isAIEnabled 
                            ? 'Tommy is currently available' 
                            : 'Tommy is currently disabled'
                      ),
                      value: isAIEnabled,
                      onChanged: (bool value) {
                        setState(() => isAIEnabled = value);
                        _updateAISettings(isEnabled: value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Hide Tommy'),
                      subtitle: Text(
                        isFloatingButtonVisible 
                            ? 'All Eyes On Tommy !' 
                            : 'Tommy is hiding in the closet !'
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
                    child: const Text('Close'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Theme.of(context).primaryColor,
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
                      return const ListTile(
                        subtitle: Text("Checking stock levels..."),
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
                          title: const Text(
                            "Low Stock Alerts",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            products.isEmpty
                                ? "No products low on stock"
                                : "${products.length} product${products.length == 1 ? '' : 's'} low on stock",
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
              title: "User Management",
              subtitle: "View and manage users",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminUsersPage()),
              ),
            ),

            const SizedBox(height: 10),

            _buildAdminCard(
              icon: Icons.inventory_2,
              title: "Product Management",
              subtitle: "Add, edit or remove products",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminProducts()),
              ),
            ),

            const SizedBox(height: 10),

            _buildAdminCard(
              icon: Icons.shopping_cart,
              title: "Order Management",
              subtitle: "View and process orders",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderManagementPage()),
              ),
            ),

            const SizedBox(height: 10),

            _buildAdminCard(
              icon: Icons.account_balance_wallet_rounded,
              title: "Promo Codes",
              subtitle: "Create Promocodes and Discounts",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DiscountAdminPage()),
              ),
            ),

            const SizedBox(height: 10),

            _buildAdminCard(
              icon: Icons.analytics,
              title: "Sales Statistics",
              subtitle: "View sales analytics and charts",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminStatisticsPage()),
              ),
            ),

            const SizedBox(height: 10),

            const SizedBox(height: 20),

            Text(
              "Admin Settings",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),

            const SizedBox(height: 10),

            _buildAdminCard(
              icon: Image.asset(
                'lib/assets/Images/Mascot/mascot-head.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
              title: "Assistant Tommy's Settings",
              subtitle: "Configure Tommy's availability",
              onTap: () => _showAISettingsDialog(context),
            ),

            const SizedBox(height: 10),

            _buildAdminCard(
              icon: Icons.settings,
              title: "App Settings",
              subtitle: "Configure application settings",
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
                          title: const Text('Category Management'),
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
                          title: const Text('Photo Uploader'),
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
                          title: const Text('Send Notifications'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationManagementPage(),
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
    required dynamic icon, // Changed from IconData to dynamic
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 1 : 2,
      color: Theme.of(context).cardColor,
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
            color: isDark ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon is IconData 
              ? Icon(
                  icon,
                  color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                )
              : icon, // Use the widget directly if it's not IconData
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}