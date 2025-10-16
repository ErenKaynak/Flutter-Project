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
import 'package:flutter/rendering.dart';

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

  // State variable to control if the bottom nav bar is collapsed
  bool _isNavBarCollapsed = false;

  // List of icons for the navigation bar items
  final List<IconData> _navIcons = [
    Icons.home_outlined,       // Home
    Icons.favorite_border_outlined, // Favorites
    Icons.shopping_bag_outlined,  // Cart
    Icons.person_outline_rounded, // Profile
    Icons.admin_panel_settings_outlined, // Admin (add if applicable)
  ];

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
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is UserScrollNotification) {
                final direction = notification.direction;
                // Handle scroll direction for collapse/expand animation
                if (direction == ScrollDirection.reverse && !_isNavBarCollapsed) { // Scroll up to collapse
                  setState(() {
                    _isNavBarCollapsed = true;
                  });
                } else if (direction == ScrollDirection.forward && _isNavBarCollapsed) { // Scroll down to expand
                  setState(() {
                    _isNavBarCollapsed = false;
                  });
                }
              }
              // Continue to bubble the notification up the tree
              return false;
            },
            child: PageView(
              controller: controller,
              physics: const NeverScrollableScrollPhysics(),
              children: screens,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              width: _isNavBarCollapsed ? 50.0 : 500,
              height: kBottomNavigationBarHeight,
              alignment: _isNavBarCollapsed ? Alignment.bottomLeft : Alignment.bottomCenter,
              margin: _isNavBarCollapsed 
                  ? const EdgeInsets.only(right: 300, bottom: 30)
                  : const EdgeInsets.symmetric(horizontal: 100.0, vertical: 30.0),
              child: _buildCustomBottomNavBar(_isNavBarCollapsed, currentScreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNavBar(bool isCollapsed, int selectedIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    
    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        // Toggle state for both left and right swipes
        if (details.primaryVelocity != 0) { // Any horizontal swipe
          setState(() {
            _isNavBarCollapsed = !_isNavBarCollapsed;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 3.0),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 400),
          crossFadeState: isCollapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isNavBarCollapsed = false;
                });
              },
              borderRadius: BorderRadius.circular(30.0),
              child: Container(
                width: 50.0,
                height: 50.0,
                child: Center(
                  child: _buildNavItem(_navIcons[selectedIndex], selectedIndex, isCollapsed),
                ),
              ),
            ),
          ),
          secondChild: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(_navIcons[0], 0, isCollapsed),
              _buildNavItem(_navIcons[1], 1, isCollapsed),
              _buildNavItem(_navIcons[2], 2, isCollapsed),
              _buildNavItem(_navIcons[3], 3, isCollapsed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, bool isCollapsed) {
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
      borderRadius: BorderRadius.circular(5.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: isCollapsed && !isSelected ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected 
              ? (themeNotifier.isSpecialModeActive 
                  ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade600.withOpacity(0.9)
                  : Colors.red.withOpacity(0.9))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Icon(
          icon,
          color: isSelected 
              ? Colors.white 
              : (themeNotifier.isSpecialModeActive 
                  ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade200 
                  : Theme.of(context).colorScheme.onSurface),
          size: 20,
        ),
      ),
    );
  }

  // Method to handle scroll direction changes from HomePage
  void _handleScroll(ScrollDirection direction) {
    if (direction == ScrollDirection.reverse && !_isNavBarCollapsed) { // Scroll up to collapse
      setState(() {
        _isNavBarCollapsed = true;
      });
    } else if (direction == ScrollDirection.forward && _isNavBarCollapsed) { // Scroll down to expand
      setState(() {
        _isNavBarCollapsed = false;
      });
    }
  }
}

class RootPage extends StatelessWidget {
  const RootPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const RootScreen();
  }
}
