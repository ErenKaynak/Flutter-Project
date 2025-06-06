import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'search_page.dart' as FavoritesPage;
import 'Home-Page/home_page.dart' as HomePage;
import 'package:engineering_project/assets/components/auth_service.dart';
import 'theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';

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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.adminDashboard,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor:
            themeNotifier.isSpecialModeActive
                ? themeNotifier
                    .getThemeColor(themeNotifier.specialTheme)
                    .shade700
                : Colors.red.shade700,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
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

              // User Management Card
              Card(
                elevation: isDark ? 1 : 2,
                color: Theme.of(context).cardColor,
                child: ListTile(
                  leading: Icon(
                    Icons.people,
                    color:
                        themeNotifier.isSpecialModeActive
                            ? themeNotifier
                                .getThemeColor(themeNotifier.specialTheme)
                                .shade700
                            : Colors.red.shade700,
                  ),
                  title: Text(
                    l10n.userManagement,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  subtitle: Text(
                    l10n.viewAndManageUsers,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
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
                  leading: Icon(
                    Icons.inventory_2,
                    color:
                        themeNotifier.isSpecialModeActive
                            ? themeNotifier
                                .getThemeColor(themeNotifier.specialTheme)
                                .shade700
                            : Colors.red.shade700,
                  ),
                  title: Text(
                    l10n.productManagement,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  subtitle: Text(
                    l10n.manageProducts,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
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
                    color:
                        themeNotifier.isSpecialModeActive
                            ? themeNotifier
                                .getThemeColor(themeNotifier.specialTheme)
                                .shade700
                            : Colors.red.shade700,
                  ),
                  title: Text(
                    l10n.orderManagement,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  subtitle: Text(
                    l10n.viewAndProcessOrders,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color:
                themeNotifier.isSpecialModeActive
                    ? themeNotifier
                        .getThemeColor(themeNotifier.specialTheme)
                        .shade700
                    : Colors.red.shade700,
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controller,
            physics: const NeverScrollableScrollPhysics(),
            children: screens,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildCustomBottomNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    
    return Container(
      // Main container for the floating bar
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9), // Consistent black/white background based on dark mode
        borderRadius: BorderRadius.circular(30.0), // Adjusted rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 3.0), // Increased horizontal padding slightly, keep vertical
      margin: const EdgeInsets.symmetric(horizontal: 100.0, vertical: 40.0), // Adjusted horizontal margin to compensate and center
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute items evenly
        children: [
          _buildNavItem(Icons.home_outlined, 0),
          _buildNavItem(Icons.favorite_border_outlined, 1),
          _buildNavItem(Icons.shopping_bag_outlined, 2),
          _buildNavItem(Icons.person_outline_rounded, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = currentScreen == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    
    return InkWell(
      onTap: () {
        setState(() {
          currentScreen = index;
        });
        controller.jumpToPage(index);
      },
      borderRadius: BorderRadius.circular(35.0), // More rounded effect for the tappable area
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Reduced horizontal padding within each item
        decoration: BoxDecoration(
          color: isSelected 
              ? (themeNotifier.isSpecialModeActive 
                  ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade600.withOpacity(0.9)
                  : Colors.red.withOpacity(0.9))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30.0), // More rounded background for selected item
        ),
        child: Icon(
          icon,
          color: isSelected 
              ? Colors.white 
              : (themeNotifier.isSpecialModeActive 
                  ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade200 
                  : Theme.of(context).colorScheme.onSurface), // Use theme onSurface color for icon
          size: 22,
        ),
      ),
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
