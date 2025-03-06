import 'package:flutter/material.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'search_page.dart';
import 'home_page.dart';

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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            //color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: NavigationBar(
            indicatorColor: Colors.white,
            height: kBottomNavigationBarHeight,
            selectedIndex: currentScreen,
            backgroundColor:
                Colors.transparent, // Set transparent background color
            //surfaceTintColor: Colors.red.shade300,
            elevation: 0,
            labelPadding: EdgeInsets.zero, // Remove default label padding
            onDestinationSelected: (value) {
              setState(() {
                currentScreen = value;
              });
              controller.jumpToPage(currentScreen);
            },
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: currentScreen == 0 ? Colors.red.shade400 : Colors.black),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_sharp, color: currentScreen == 1 ? Colors.red.shade400 : Colors.black,),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined, color: currentScreen == 2 ? Colors.red.shade400 : Colors.black),
                label: 'Cart',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, color: currentScreen == 3 ? Colors.red.shade400 : Colors.black),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
