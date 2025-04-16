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
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Center(child: const Text("Admin Dashboard")),
        foregroundColor: Colors.white,
        backgroundColor: Colors.red.shade700,
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Admin Controls",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // User Management Card
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.people, color: Colors.red.shade700),
                  title: const Text("User Management"),
                  subtitle: const Text("View and manage users"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminUsersPage()),
              ),
                    // Navigate to user management screen
                  
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Product Management Card
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.inventory_2, color: Colors.red.shade700),
                  title: const Text("Product Management"),
                  subtitle: const Text("Add, edit or remove products"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminProducts()),
              ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Order Management Card
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.shopping_cart, color: Colors.red.shade700),
                  title: const Text("Order Management"),
                  subtitle: const Text("View and process orders"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderManagementPage()),
              ),
                    // Navigate to order management screen
                  
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Statistics Card
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.account_balance_wallet_rounded, color: Colors.red.shade700),
                  title: const Text("Promo Codes"),
                  subtitle: const Text("Create Promocodes and Discounts"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                    context,
                       MaterialPageRoute(builder: (context) => const DiscountAdminPage()),
                      ),
                ),
              ),
              
              const SizedBox(height: 20),

              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.bar_chart, color: Colors.red.shade700),
                  title: const Text("Statistics"),
                  subtitle: const Text("View sales and user analytics"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to statistics screen
                  },
                ),
              ),

              const SizedBox(height: 20),
              
              // Admin Settings
              const Text(
                "Admin Settings",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 10),
              
              // App Settings Card
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.settings, color: Colors.red.shade700),
                  title: const Text("App Settings"),
                  subtitle: const Text("Configure application settings"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to app settings screen
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }
}