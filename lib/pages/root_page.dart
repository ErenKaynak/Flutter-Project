import 'package:engineering_project/pages/Home_page.dart';
import 'package:engineering_project/pages/cart_page.dart';
import 'package:engineering_project/pages/profile_page.dart';
import 'package:engineering_project/pages/search_page.dart';
import 'package:flutter/material.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  late PageController controller;
  int currentScreen = 0;
  List<Widget> screens = [HomePage(), SearchPage(), CartPage(), ProfilePage()];

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: currentScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller,
        physics: NeverScrollableScrollPhysics(),
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        indicatorColor: Colors.red.shade400,
        height: kBottomNavigationBarHeight,
        selectedIndex: currentScreen,
        backgroundColor: Colors.grey.shade200,
        surfaceTintColor: Colors.red.shade300,
        elevation: 0,
        onDestinationSelected: (value) {
          setState(() {
            currentScreen = value;
          });
          controller.jumpToPage(currentScreen);
        },
        destinations: [
          NavigationDestination(icon: Icon(Icons.home, color: Colors.grey[400]), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search, color: Colors.grey[400]), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.shopping_bag_rounded, color: Colors.grey[400]),label: 'Cart',),
          NavigationDestination(icon: Icon(Icons.person, color: Colors.grey[400]), label: 'Profile'),
        ],
      ),
    );
  }
}
