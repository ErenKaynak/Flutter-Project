import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'search_page.dart';
import 'home_page.dart';
import 'package:engineering_project/assets/components/auth_service.dart';

// Import or create an admin page
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
        title: const Text("Admin Dashboard"),
        foregroundColor: Colors.white,
        backgroundColor: Colors.red.shade500,
      ),
      body: Center(
        child: SingleChildScrollView(
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
                  leading: Icon(Icons.people, color: Colors.red.shade500),
                  title: const Text("User Management"),
                  subtitle: const Text("View and manage users"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to user management screen
                  },
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Product Management Card
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.inventory_2, color: Colors.red.shade500),
                  title: const Text("Product Management"),
                  subtitle: const Text("Add, edit or remove products"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to product management screen
                  },
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Order Management Card
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.shopping_cart, color: Colors.red.shade500),
                  title: const Text("Order Management"),
                  subtitle: const Text("View and process orders"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to order management screen
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  late PageController controller;
  int currentScreen = 0;
  List<Widget> screens = [
    const HomePage(), 
    const SearchPage(), 
    const CartPage(), 
    const ProfilePage()
  ];
  bool isAdmin = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: currentScreen);
    checkAdminStatus();
  }

  Future<void> checkAdminStatus() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Check if user is admin using the AuthService
      bool adminStatus = await AuthService().isUserAdmin();
      
      if (adminStatus) {
        setState(() {
          isAdmin = true;
          screens = [
            const HomePage(), 
            const SearchPage(), 
            const CartPage(), 
            const ProfilePage(),
            const AdminPage()
          ];
        });
      }
    } catch (e) {
      print("Error checking admin status: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: NavigationBar(
            indicatorColor: Colors.white,
            height: kBottomNavigationBarHeight,
            selectedIndex: currentScreen,
            backgroundColor: Colors.transparent,
            elevation: 0,
            labelPadding: EdgeInsets.zero,
            onDestinationSelected: (value) {
              setState(() {
                currentScreen = value;
              });
              controller.jumpToPage(currentScreen);
            },
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, 
                  color: currentScreen == 0 ? Colors.red.shade400 : Colors.black, size: 30),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_sharp, 
                  color: currentScreen == 1 ? Colors.red.shade400 : Colors.black, size: 30),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined, 
                  color: currentScreen == 2 ? Colors.red.shade400 : Colors.black, size: 30),
                label: 'Cart',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, 
                  color: currentScreen == 3 ? Colors.red.shade400 : Colors.black, size: 30),
                label: 'Profile',
              ),
              // Admin navigation destination - only shown to admin users
              if (isAdmin)
                NavigationDestination(
                  icon: Icon(Icons.admin_panel_settings_outlined, 
                    color: currentScreen == 4 ? Colors.red.shade400 : Colors.black, size: 30),
                  label: 'Admin',
                ),
            ],
          ),
        ),
      ),
    );
  }
}