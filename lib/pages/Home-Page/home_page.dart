import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:engineering_project/pages/cart_page.dart' as CartPage;
import 'package:engineering_project/pages/login_page.dart';
import 'package:engineering_project/pages/notifications_page.dart';
import 'package:engineering_project/pages/product-detail-page.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:engineering_project/assets/components/notification_service.dart';
import 'package:engineering_project/pages/Home-Page/cart_manager.dart';
import 'package:engineering_project/pages/Home-Page/favorites_page.dart';
import 'package:engineering_project/pages/Home-Page/widgets/banner_section.dart';
import 'package:engineering_project/pages/Home-Page/widgets/categories_section.dart';
import 'package:engineering_project/pages/Home-Page/widgets/product_grid.dart';
import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:engineering_project/pages/Home-Page/widgets/most_viewed_section.dart';

class HomePage extends StatefulWidget {
  // Callback for scroll events to notify parent
  final ValueChanged<ScrollDirection>? onScroll;

  const HomePage({Key? key, this.onScroll}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String _selectedCategory = "All";
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> categories = [];
  bool _isLoading = true;
  List<String> favoriteProductIds = [];
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final CartManager _cartManager = CartManager();
  final Map<String, AnimationController> _animationControllers = {};
  String? _userProfilePicture;

  final Map<String, AnimationController> _colorAnimationControllers = {};
  final Map<String, Animation<Color?>> _colorAnimations = {};
  final Map<String, AnimationController> _tickAnimationControllers = {};
  final Map<String, Animation<double>> _tickAnimations = {};
  final Map<String, bool> _isAddingToCartMap = {};

  bool _isDisposed = false;
  String _userName = "Guest";

  // Banner related variables
  List<Map<String, dynamic>> _banners = [];
  bool _isBannersLoading = true;
  int _currentBannerIndex = 0;

  StreamSubscription<QuerySnapshot>? _categoriesSubscription;

  @override
  void initState() {
    super.initState();
    _cartManager.loadCart();
    _cartManager.addListener(_updateUI);
    _getUserProfile();
    _setupCategoriesListener();
    
    Future.microtask(() {
      if (mounted) {
        _loadBanners();
      }
    });

    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });

    _loadInitialData();
  }

  void _setupCategoriesListener() {
    _categoriesSubscription = FirebaseFirestore.instance
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          categories = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unnamed Category',
              'iconPath': data['iconPath'] ?? '',
              'order': data['order'] ?? 999999,
            };
          }).toList();
        });
      }
    }, onError: (error) {
      print('Error in categories stream: $error');
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await fetchProducts();
      await fetchFavorites();

      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error loading initial data: $error');
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateUI() {
    if (mounted && !_isDisposed) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    _cartManager.removeListener(_updateUI);
    _categoriesSubscription?.cancel();
    
    // Dispose all animation controllers
    _animationControllers.forEach((_, controller) => controller.dispose());
    _animationControllers.clear(); // Clear the map after disposing

    super.dispose();
  }

  Future<void> _getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _userName = "Guest";
        _userProfilePicture = null;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final profileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';

      if (mounted) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? 'User';
          _userProfilePicture =
              profileImageUrl.isNotEmpty ? profileImageUrl : null;
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      if (mounted) {
        setState(() {
          _userName = "User";
          _userProfilePicture = null;
        });
      }
    }
  }

  void _initializeAnimationControllers(List<Map<String, dynamic>> productsToInitialize) {
    try {
      // Dispose controllers and listeners for products no longer in the list
      _animationControllers.keys.toList().forEach((productId) {
        if (!productsToInitialize.any((product) => product['id'] == productId)) {
          _animationControllers[productId]?.dispose();
          _animationControllers.remove(productId);
          _isAddingToCartMap.remove(productId); // Also remove from isAddingToCartMap
        }
      });

      for (var product in productsToInitialize) {
        final dynamic productId = product['id'];
        // Ensure productId is a non-null string before creating controllers
        if (productId == null || productId is! String || productId.isEmpty) {
           print('Skipping product with invalid ID during initialization: ${product['name']}');
           continue;
        }

        final String validProductId = productId;

        // Create controller only if it doesn't exist
        if (!_animationControllers.containsKey(validProductId)) {
           final controller = AnimationController(
            vsync: this,
            duration: Duration(milliseconds: 1000),
          );
          _animationControllers[validProductId] = controller;
           _isAddingToCartMap[validProductId] = false; // Ensure this is initialized

           // Add status listener to reset animation and state
           controller.addStatusListener((status) {
             if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
               _resetAnimations(validProductId);
             }
           });
        }
      }

    } catch (e) {
      print('Error initializing animation controllers: $e');
    }
  }

  Future<void> fetchProducts() async {
    if (!mounted) return;

    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('products').get();

      final List<Map<String, dynamic>> loadedProducts = [];

      snapshot.docs.forEach((doc) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data != null && doc.id != null && doc.id.isNotEmpty) {
          print('Product: ${data['name']}, Image path: ${data['imagePath']}');
          String priceString = data['price']?.toString() ?? '0';

          loadedProducts.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Product',
            'price': priceString,
            'category': data['category'] ?? 'Uncategorized',
            'image': data['imagePath'] ?? 'lib/assets/Images/placeholder.png',
            'description': data['description'] ?? 'No description available',
            'stock': data['stock'] ?? 0,
            'averageRating': (data['averageRating'] ?? 0.0).toDouble(),
            'ratingCount': data['ratingCount'] ?? 0,
          });
        }
      });

      // Initialize controllers here, before setState
      _initializeAnimationControllers(loadedProducts);

      if (!mounted) return;

      setState(() {
        products = loadedProducts;
      });

    } catch (error) {
      print('Error fetching products: $error');
    }
  }

  Future<void> fetchFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          favoriteProductIds = [];
        });
        return;
      }

      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .doc(user.uid)
          .collection('userFavorites')
          .get();

      final List<String> loadedFavorites = [];
      favoritesSnapshot.docs.forEach((doc) {
        loadedFavorites.add(doc.id);
      });

      if (mounted) {
        setState(() {
          favoriteProductIds = loadedFavorites;
        });
      }
    } catch (error) {
      print('Error fetching favorites: $error');
    }
  }

  Future<void> toggleFavorite(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.pleaseSignIn),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text(AppLocalizations.of(context)!.signIn,
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    final productId = product['id'];
    final isFavorite = favoriteProductIds.contains(productId);

    try {
      final favRef = FirebaseFirestore.instance
          .collection('favorites')
          .doc(user.uid)
          .collection('userFavorites')
          .doc(productId);

      if (isFavorite) {
        await favRef.delete();
        if (mounted) {
          setState(() {
            favoriteProductIds.remove(productId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.removedFromFavorites),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await favRef.set({
          'name': product['name'],
          'price': product['price'],
          'image': product['image'],
          'category': product['category'],
          'description': product['description'],
          'stock': product['stock'],
          'addedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          setState(() {
            favoriteProductIds.add(productId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.addedToFavorites),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.failedToUpdateFavorites),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredProducts {
    if (_searchQuery.isNotEmpty) {
      return products
          .where(
            (product) =>
                product["name"].toString().toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                product["description"].toString().toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
          )
          .toList();
    } else if (_selectedCategory == "All") {
      return products;
    } else {
      return products
          .where((product) => product["category"] == _selectedCategory)
          .toList();
    }
  }

  void _selectCategory(String category) {
    if (mounted) {
      setState(() {
        _selectedCategory = category;
        _searchController.clear();
      });
    }
  }

  void _navigateToProductDetail(Map<String, dynamic> product) {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(productId: product["id"]),
      ),
    );
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    final productId = product['id'];
    // Prevent adding to cart if already processing for this product or invalid ID
    if (productId == null || productId is! String || productId.isEmpty || _isAddingToCartMap[productId] == true) {
      print('Attempted to add invalid product or product already being added: $productId');
      return;
    }

    _isAddingToCartMap[productId] = true;
    // Find the animation controller for this product
    final controller = _animationControllers[productId];

    // Start the animation if the controller exists
    if (controller != null) {
       print('Starting animation for $productId'); // Log for debugging
      controller.forward();
       // We no longer await here, allowing the UI update to happen immediately
    } else {
      print('No animation controller found for $productId'); // Log for debugging
       // If no controller, we still proceed with cart logic but without animation
       if (mounted) {
         setState(() {}); // Trigger rebuild to show isAddingToCart state if needed
       }
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.pleaseLoginToAdd),
              duration: Duration(seconds: 2),
            ),
          );
        }
        // Reset state immediately as no cart action will happen
         _isAddingToCartMap[productId] = false;
         if (mounted) setState(() {}); // Update UI
        // Dispose the temporary controller if it was created (no longer creating temporary controllers here)
        // if (!_animationControllers.containsKey(productId)) controller?.dispose();
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');

      final docSnapshot = await cartRef.doc(productId).get();

      if (docSnapshot.exists) {
        final currentQuantity = docSnapshot.data()?['quantity'] ?? 1;
        final newQuantity = (currentQuantity + 1).clamp(1, 10);
        batch.update(cartRef.doc(productId), {'quantity': newQuantity});
      } else {
        batch.set(cartRef.doc(productId), {
          'name': product['name'],
          'price': product['price'],
          'imagePath': product['image'],
          'quantity': 1,
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .addedToCartMessage(product["name"], 1)),
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.viewCart,
              onPressed: () {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage.CartPage(),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }

      // We no longer await the animation duration here before resetting.
      // The animation reset will be handled by the controller's status listener.
      // await Future.delayed(Duration(milliseconds: 800));\n\n      // The animation reset is now handled by the controller status listener
      // if (mounted) {\n      //   _resetAnimations(productId);\n      // }\n\n    } catch (e) {\n      print(\'Error adding item to cart: $e\');\n      // Only reset state, animation reset is via listener\n       _isAddingToCartMap[productId] = false;\n       if (mounted) setState(() {}); // Update UI on error\n      if (mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text(AppLocalizations.of(context)!.failedToAddToCart),\n            duration: Duration(seconds: 2),\n          ),\n        );\n      }\n    } finally {\n      // The isAddingToCartMap state is now reset in _resetAnimations which is called by the controller listener.\n      // Dispose temporary controllers if created (no longer creating temporary controllers here)\n      // if (!_animationControllers.containsKey(productId)) controller?.dispose();\n    }\n  }
    } catch (e) {
      print('Error adding item to cart: $e');
      // Only reset state, animation reset is via listener
       _isAddingToCartMap[productId] = false;
       if (mounted) setState(() {}); // Update UI on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToAddToCart),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _resetAnimations(String productId) {
    final controller = _animationControllers[productId];

    if (controller?.isAnimating ?? false) {
      controller?.stop();
    }
    controller?.reset();

    if (mounted) {
      setState(() {
        _isAddingToCartMap[productId] = false;
      });
    }
  }

  Future<void> _loadBanners() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isBannersLoading = true;
      });

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('banners')
          .orderBy('order')
          .where('isActive', isEqualTo: true)
          .get();

      if (!mounted) return;

      final List<Map<String, dynamic>> loadedBanners = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'imageUrl': data['imageUrl'] ?? '',
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'themeColor': data['themeColor'] ?? 'red',
          'isActive': data['isActive'] ?? true,
        };
      }).toList();

      setState(() {
        _banners = loadedBanners;
        _isBannersLoading = false;
      });
    } catch (e) {
      print('Error loading banners: $e');
      if (mounted) {
        setState(() {
          _banners = [];
          _isBannersLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final specialColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : null;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          elevation: 10,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              themeNotifier.isSpecialModeActive
                  ? 'lib/assets/Images/app-icon-light-${themeNotifier.specialTheme.toString().split('.').last}.png'
                  : 'lib/assets/Images/app-icon-light.png',
              fit: BoxFit.contain,
            ),
          ),
          title: Container(
            height: 40,
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchProducts,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                fillColor: isDark ? Colors.grey.shade800 : Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 22,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                alignLabelWithHint: true,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  color: isDark ? Colors.white : Colors.black,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsPage()),
                    );
                  },
                ),
                StreamBuilder<int>(
                  stream: NotificationService.getUnreadCount(),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    if (unreadCount == 0) return SizedBox.shrink();
                    
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: themeNotifier.isSpecialModeActive
                              ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                              : Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shopping_cart,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartPage.CartPage(),
                        ),
                      );
                    }
                  },
                ),
                if (_cartManager.itemCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: themeNotifier.isSpecialModeActive
                            ? specialColor
                            : (themeNotifier.isBlackMode
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.red),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_cartManager.itemCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 20),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadInitialData,
                child: _searchQuery.isNotEmpty
                    ? CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.searchProducts,
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.products(filteredProducts.length),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ProductGrid(
                            products: filteredProducts,
                            favoriteProductIds: favoriteProductIds,
                            animationControllers: _animationControllers,
                            isAddingToCartMap: _isAddingToCartMap,
                            onAddToCart: _addToCart,
                            onToggleFavorite: toggleFavorite,
                            onProductTap: _navigateToProductDetail,
                            vsync: this,
                          ),
                        ],
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(16.0),
                                  margin: EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: themeNotifier.isSpecialModeActive
                                          ? [
                                              specialColor ?? Colors.red,
                                              isDark
                                                  ? Colors.grey.shade900
                                                  : Colors.grey.shade100,
                                            ]
                                          : (themeNotifier.isBlackMode
                                              ? [
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                  Colors.grey.shade900,
                                                ]
                                              : (isDark
                                                  ? [
                                                      Colors.red.shade900,
                                                      Colors.grey.shade900,
                                                    ]
                                                  : [
                                                      Colors.red.shade500,
                                                      Colors.red.shade100,
                                                    ])),
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black26
                                            : Colors.black12,
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor:
                                            themeNotifier.isSpecialModeActive
                                                ? specialColor
                                                : (isDark
                                                    ? Colors.red.shade700
                                                    : Colors.red.shade300),
                                        backgroundImage: _userProfilePicture !=
                                                    null &&
                                                _userProfilePicture!.isNotEmpty
                                            ? NetworkImage(_userProfilePicture!)
                                            : null,
                                        child: _userProfilePicture == null ||
                                                _userProfilePicture!.isEmpty
                                            ? Icon(
                                                Icons.person,
                                                size: 36,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!
                                                  .welcome,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.black54,
                                              ),
                                            ),
                                            Text(
                                              _userName,
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                BannerSection(
                                  banners: _banners,
                                  isLoading: _isBannersLoading,
                                  onPageChanged: (index, reason) {
                                    if (mounted) {
                                      setState(() {
                                        _currentBannerIndex = index;
                                      });
                                    }
                                  },
                                ),
                                CategoriesSection(
                                  categories: categories,
                                  selectedCategory: _selectedCategory,
                                  onCategorySelected: _selectCategory,
                                ),
                                MostViewedSection(
                                  onProductTap: _navigateToProductDetail,
                                  onAddToCart: _addToCart,
                                  onToggleFavorite: toggleFavorite,
                                  favoriteProductIds: favoriteProductIds,
                                  animationControllers: _animationControllers,
                                  isAddingToCartMap: _isAddingToCartMap,
                                  vsync: this,
                                  selectedCategory: _selectedCategory,
                                ),
                                Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedCategory == "All"
                                            ? AppLocalizations.of(context)!.bestDeals
                                            : _selectedCategory,
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        AppLocalizations.of(context)!.products(filteredProducts.length),
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ProductGrid(
                            products: filteredProducts,
                            favoriteProductIds: favoriteProductIds,
                            animationControllers: _animationControllers,
                            isAddingToCartMap: _isAddingToCartMap,
                            onAddToCart: _addToCart,
                            onToggleFavorite: toggleFavorite,
                            onProductTap: _navigateToProductDetail,
                            vsync: this,
                          ),
                        ],
                      ),
              ),
      ),
    );
  }
} 