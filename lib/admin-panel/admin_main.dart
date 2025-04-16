import 'package:engineering_project/admin-panel/admin_discount.dart';
import 'package:engineering_project/admin-panel/admin_order_management.dart';
import 'package:engineering_project/admin-panel/admin_products.dart';
import 'package:engineering_project/admin-panel/admin_user.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
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
              icon: Icons.settings,
              title: "App Settings",
              subtitle: "Configure application settings",
              onTap: () {
                // Navigate to app settings screen
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
          child: Icon(
            icon,
            color: isDark ? Colors.red.shade400 : Colors.red.shade700,
          ),
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