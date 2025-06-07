import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomepageLayoutPage extends StatefulWidget {
  const HomepageLayoutPage({Key? key}) : super(key: key);

  @override
  _HomepageLayoutPageState createState() => _HomepageLayoutPageState();
}

class _HomepageLayoutPageState extends State<HomepageLayoutPage> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.phone_android, 'name': 'Phones'},
    {'icon': Icons.laptop, 'name': 'Laptops'},
    {'icon': Icons.headphones, 'name': 'Audio'},
    {'icon': Icons.watch, 'name': 'Watches'},
    {'icon': Icons.camera_alt, 'name': 'Cameras'},
  ];

  // List to track the order of components
  List<Map<String, dynamic>> components = [
    {'id': 'welcome', 'name': 'Welcome Container', 'enabled': true, 'order': 0},
    {'id': 'banner', 'name': 'Banner', 'enabled': true, 'order': 1},
    {'id': 'categories', 'name': 'Category Circles', 'enabled': true, 'order': 2},
    {'id': 'mostViewed', 'name': 'Most Viewed Products', 'enabled': true, 'order': 3},
    {'id': 'bestDeals', 'name': 'Best Deals', 'enabled': true, 'order': 4},
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, AnimationController> _animationControllers = {};
  Map<String, Animation<double>> _animations = {};

  @override
  void initState() {
    super.initState();
    _loadLayoutConfiguration();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    for (var component in components) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
      _animationControllers[component['id']] = controller;
      _animations[component['id']] = animation;
      controller.forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLayoutConfiguration() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('layout_configuration')
          .doc('homepage')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final List<dynamic> savedComponents = data['components'] ?? [];
        
        if (savedComponents.isNotEmpty) {
          setState(() {
            components = savedComponents.map((component) => Map<String, dynamic>.from(component)).toList();
            components.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
          });
        }
      }
    } catch (e) {
      print('Error loading layout configuration: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLayoutConfiguration() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Update order numbers before saving
      for (int i = 0; i < components.length; i++) {
        components[i]['order'] = i;
      }

      await FirebaseFirestore.instance
          .collection('layout_configuration')
          .doc('homepage')
          .set({
        'components': components,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Layout saved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error saving layout configuration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save layout configuration'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _reorderComponents(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = components.removeAt(oldIndex);
      components.insert(newIndex, item);

      // Animate the moved item
      final controller = _animationControllers[item['id']];
      if (controller != null) {
        controller.forward(from: 0.0);
      }
    });
    _saveLayoutConfiguration();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    // final themeColor = themeNotifier.isSpecialModeActive 
    //     ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
    //     : Colors.red;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.homepageLayout, // This localization key needs to be added
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: isDark 
            ? (themeNotifier.isSpecialModeActive 
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade900 
                : Colors.red.shade900)
            : (themeNotifier.isSpecialModeActive 
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade700 
                : Colors.red.shade700),
        foregroundColor: Colors.white,
        elevation: isDark ? 0 : 2,
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveLayoutConfiguration,
              tooltip: 'Save Layout',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? Colors.grey[900] : Colors.grey[100],
          child: Row(
            children: [
              Icon(Icons.info_outline, 
                color: isDark ? Colors.white70 : Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Drag and drop components to reorder them. Toggle switches to show/hide components.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Component List
        Expanded(
          child: ReorderableListView(
            onReorder: _reorderComponents,
            children: components.map((component) {
              final animation = _animations[component['id']];
              return SizeTransition(
                key: ValueKey(component['id']),
                sizeFactor: animation!,
                child: FadeTransition(
                  opacity: animation,
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isDark ? Colors.grey[800] : Colors.white,
                    elevation: 4,
                    child: ListTile(
                      leading: Icon(
                        _getComponentIcon(component['id']),
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      title: Text(
                        component['name'],
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_upward,
                              color: components.indexOf(component) > 0 
                                  ? (isDark ? Colors.white70 : Colors.black54) 
                                  : Colors.grey,
                            ),
                            onPressed: components.indexOf(component) > 0
                                ? () {
                                    setState(() {
                                      final index = components.indexOf(component);
                                      final item = components.removeAt(index);
                                      components.insert(index - 1, item);
                                    });
                                    _saveLayoutConfiguration();
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_downward,
                              color: components.indexOf(component) < components.length - 1
                                  ? (isDark ? Colors.white70 : Colors.black54)
                                  : Colors.grey,
                            ),
                            onPressed: components.indexOf(component) < components.length - 1
                                ? () {
                                    setState(() {
                                      final index = components.indexOf(component);
                                      final item = components.removeAt(index);
                                      components.insert(index + 1, item);
                                    });
                                    _saveLayoutConfiguration();
                                  }
                                : null,
                          ),
                          Switch(
                            value: component['enabled'],
                            onChanged: (value) {
                              setState(() {
                                component['enabled'] = value;
                              });
                              _saveLayoutConfiguration();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

IconData _getComponentIcon(String componentId) {
  switch (componentId) {
    case 'welcome':
      return Icons.waving_hand;
    case 'banner':
      return Icons.image;
    case 'categories':
      return Icons.category;
    case 'mostViewed':
      return Icons.visibility;
    case 'bestDeals':
      return Icons.local_offer;
    default:
      return Icons.widgets;
  }
}
} 