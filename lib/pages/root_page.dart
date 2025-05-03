import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'search_page.dart' as FavoritesPage;
import 'home_page.dart' as HomePage;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: SingleChildScrollView(
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

              // User Management Card
              Card(
                elevation: isDark ? 1 : 2,
                color: Theme.of(context).cardColor,
                child: ListTile(
                  leading: Icon(Icons.people, color: Theme.of(context).primaryColor),
                  title: Text(
                    "User Management",
                    style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color),
                  ),
                  subtitle: Text(
                    "View and manage users",
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onTap: () {
                    // Navigate to user management screen
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Product Management Card
              Card(
                elevation: isDark ? 1 : 2,
                color: Theme.of(context).cardColor,
                child: ListTile(
                  leading: Icon(Icons.inventory_2, color: Theme.of(context).primaryColor),
                  title: Text(
                    "Product Management",
                    style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color),
                  ),
                  subtitle: Text(
                    "Add, edit or remove products",
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onTap: () {
                    // Navigate to product management screen
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Order Management Card
              Card(
                elevation: isDark ? 1 : 2,
                color: Theme.of(context).cardColor,
                child: ListTile(
                  leading: Icon(
                    Icons.shopping_cart,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    "Order Management",
                    style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color),
                  ),
                  subtitle: Text(
                    "View and process orders",
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).iconTheme.color,
                  ),
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
    HomePage.HomePage(),
    const FavoritesPage.FavoritesPage(),
    const CartPage(),
    const ProfilePage(),
  ];
  bool isAdmin = false;
  bool isLoading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: currentScreen);
    checkAdminStatus();
  }

  @override
  void dispose() {
    _mounted = false;
    controller.dispose();
    super.dispose();
  }

  Future<void> checkAdminStatus() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Check if user is admin using the AuthService
      bool adminStatus = await AuthService().isUserAdmin();

      if (adminStatus && _mounted) {
        setState(() {
          isAdmin = true;
          screens = [
            HomePage.HomePage(),
            const FavoritesPage.FavoritesPage(),
            const CartPage(),
            const ProfilePage(),
            const AdminPage(),
          ];
        });
      }
    } catch (e) {
      print("Error checking admin status: $e");
    } finally {
      if (_mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            color: isDark ? Colors.grey[900] : Colors.white,
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: NavigationBar(
            indicatorColor: isDark 
                ? Colors.grey[800]!
                : Colors.white,
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
              _buildNavigationDestination(Icons.home_outlined, 'Home', 0),
              _buildNavigationDestination(Icons.favorite_border_outlined, 'Favorites', 1),
              _buildNavigationDestination(Icons.shopping_bag_outlined, 'Cart', 2),
              _buildNavigationDestination(Icons.person_outline_rounded, 'Profile', 3),
              if (isAdmin)
                _buildNavigationDestination(Icons.admin_panel_settings_outlined, 'Admin', 4),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavigationDestination(IconData icon, String label, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = currentScreen == index;
    
    return NavigationDestination(
      icon: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).primaryColor
            : isDark
                ? Colors.grey[400]
                : Colors.black54,
        size: 30,
      ),
      label: label,
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const RootScreen();
  }
}
