import 'package:engineering_project/pages/root_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/pages/product-detail-page.dart';
import 'package:engineering_project/pages/cart_page.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class FavoritesPage extends StatefulWidget {
  final Function? onFavoritesChanged;

  const FavoritesPage({Key? key, this.onFavoritesChanged}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> favoriteProducts = [];
  // Add this new Map to track unfavorited products
  final Map<String, bool> _unfavoritedProducts = {};
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, AnimationController> _colorAnimationControllers = {};
  final Map<String, Animation<Color?>> _colorAnimations = {};
  final Map<String, AnimationController> _tickAnimationControllers = {};
  final Map<String, Animation<double>> _tickAnimations = {};
  final Map<String, bool> _isAddingToCartMap = {};
  final NumberFormat _priceFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  @override
  void dispose() {
    _animationControllers.forEach((_, controller) => controller.dispose());
    _colorAnimationControllers.forEach((_, controller) => controller.dispose());
    _tickAnimationControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _initializeAnimationControllers() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    _animationControllers.forEach((_, controller) => controller.dispose());
    _colorAnimationControllers.forEach((_, controller) => controller.dispose());
    _tickAnimationControllers.forEach((_, controller) => controller.dispose());
    _animationControllers.clear();
    _colorAnimationControllers.clear();
    _colorAnimations.clear();
    _tickAnimationControllers.clear();
    _tickAnimations.clear();
    _isAddingToCartMap.clear();

    for (var product in favoriteProducts) {
      final productId = product['id'];
      
      final animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300),
      );
      _animationControllers[productId] = animationController;

      final colorController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300),
      );
      _colorAnimationControllers[productId] = colorController;
      _colorAnimations[productId] = ColorTween(
        begin: themeNotifier.isSpecialModeActive
            ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade400
            : Colors.red.shade400,
        end: Colors.grey.shade400,
      ).animate(colorController);

      final tickController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500),
      );
      _tickAnimationControllers[productId] = tickController;
      _tickAnimations[productId] = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: tickController, curve: Curves.elasticOut),
      );
      _isAddingToCartMap[productId] = false;
    }
  }

  Future<void> fetchFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          favoriteProducts = [];
          _isLoading = false;
        });
        return;
      }

      final favoritesSnapshot =
          await FirebaseFirestore.instance
              .collection('favorites')
              .doc(user.uid)
              .collection('userFavorites')
              .orderBy('addedAt', descending: true)
              .get();

      final List<Map<String, dynamic>> loadedFavorites = [];
      final List<Future<void>> stockFutures = [];
      
      // First, load basic product info from favorites
      for (var doc in favoritesSnapshot.docs) {
        final data = doc.data();
        final productId = doc.id;
        
        final productMap = {
          'id': productId,
          'name': data['name'] ?? 'Unknown Product',
          'price': data['price']?.toString() ?? '0',
          'image': data['image'] ?? 'lib/assets/Images/placeholder.png',
          'category': data['category'] ?? 'Uncategorized',
          'description': data['description'] ?? 'No description available',
          'stock': data['stock'] ?? 0, // Default stock value
        };
        
        loadedFavorites.add(productMap);
        
        // Create a future to fetch the latest stock for this product
        final stockFuture = FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get()
            .then((productDoc) {
              if (productDoc.exists) {
                final productData = productDoc.data();
                if (productData != null && productData.containsKey('stock')) {
                  // Update the stock value with the latest from products collection
                  final index = loadedFavorites.indexWhere((p) => p['id'] == productId);
                  if (index >= 0) {
                    loadedFavorites[index]['stock'] = productData['stock'] ?? 0;
                  }
                }
              }
            })
            .catchError((error) {
              print('Error fetching product stock: $error');
            });
            
        stockFutures.add(stockFuture);
      }
      
      // Wait for all stock fetch operations to complete
      await Future.wait(stockFutures);

      setState(() {
        favoriteProducts = loadedFavorites;
        _isLoading = false;
      });
      _initializeAnimationControllers();
    } catch (error) {
      print('Error fetching favorites: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> removeFromFavorites(String productId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      // Mark the product as unfavorited in the UI
      setState(() {
        _unfavoritedProducts[productId] = true;
      });

      // Still remove from Firestore
      await FirebaseFirestore.instance
          .collection('favorites')
          .doc(user.uid)
          .collection('userFavorites')
          .doc(productId)
          .delete();
  
      // Notify parent if needed
      if (widget.onFavoritesChanged != null) {
        widget.onFavoritesChanged!();
      }
  
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.removedFromFavorites),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error removing from favorites: $e');
      // Reset unfavorited status if there's an error
      setState(() {
        _unfavoritedProducts.remove(productId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToRemove),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> addToCart(Map<String, dynamic> product) async {
    final l10n = AppLocalizations.of(context)!;
    final productId = product['id'];
    
    if (_isAddingToCartMap[productId] == true) return;
    
    try {
      setState(() {
        _isAddingToCartMap[productId] = true;
      });

      final colorController = _colorAnimationControllers[productId];
      final tickController = _tickAnimationControllers[productId];

      if (colorController != null && tickController != null) {
        await colorController.forward();
        await tickController.forward();
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseLoginToAdd),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      // Fetch the latest product data to check current stock
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      
      if (!productDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productNoLongerAvailable),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      final productData = productDoc.data()!;
      final int currentStock = productData['stock'] is int ? productData['stock'] : 0;
      
      if (currentStock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.outOfStock),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(productId);

      final docSnapshot = await cartRef.get();

      if (docSnapshot.exists) {
        final currentQuantity = docSnapshot.data()?['quantity'] ?? 1;
        final newQuantity = (currentQuantity + 1).clamp(1, 10);
        await cartRef.update({'quantity': newQuantity});
      } else {
        await cartRef.set({
          'name': product['name'],
          'price': product['price'],
          'imagePath': product['image'],
          'quantity': 1,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addedToCart(product["name"])),
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: l10n.viewCart,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
          ),
        ),
      );

      // Reset animations after a delay
      await Future.delayed(Duration(milliseconds: 1000));
      if (mounted) {
        if (colorController != null && tickController != null) {
          await colorController.reverse();
          await tickController.reverse();
        }
        setState(() {
          _isAddingToCartMap[productId] = false;
        });
      }
    } catch (e) {
      print('Error adding item to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToAddToCart),
          duration: Duration(seconds: 2),
        ),
      );
      if (mounted) {
        setState(() {
          _isAddingToCartMap[productId] = false;
        });
      }
    }
  }

  void _navigateToProductDetail(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(productId: product["id"]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            themeNotifier.isSpecialModeActive
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                : (isDark
                    ? Theme.of(context).appBarTheme.backgroundColor
                    : Colors.red.shade700),
        title: Text(
          l10n.myFavorites,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading && favoriteProducts.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: fetchFavorites,
              tooltip: l10n.refresh,
            ),
        ],
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : favoriteProducts.isEmpty
              ? _buildEmptyFavorites()
              : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyFavorites() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color:
                themeNotifier.isSpecialModeActive
                    ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                    : Colors.red,
          ),
          SizedBox(height: 1),
          Text(
            l10n.noFavoritesYet,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 1),
          Text(
            l10n.itemsYouFavorite,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          SizedBox(height: 1),
          ElevatedButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RootScreen()),
                ),
            child: Text(l10n.exploreProducts),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              foregroundColor: Colors.white,
              backgroundColor:
                  themeNotifier.isSpecialModeActive
                      ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                      : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return RefreshIndicator(
      onRefresh: fetchFavorites,
      child: GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 15,
          childAspectRatio: 0.75,
        ),
        itemCount: favoriteProducts.length,
        itemBuilder: (context, index) {
          final product = favoriteProducts[index];
          final int stock = product["stock"] is int ? product["stock"] : 0;
          final bool isOutOfStock = stock <= 0;

          return _buildFavoriteCard(
            product: product,
            isOutOfStock: isOutOfStock,
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard({
    required Map<String, dynamic> product,
    required bool isOutOfStock,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    if (!_animationControllers.containsKey(product['id'])) {
      _animationControllers[product['id']] = AnimationController(
        vsync: this,
        duration: Duration(seconds: 2),
      );
    }
    if (!_colorAnimationControllers.containsKey(product['id'])) {
      _colorAnimationControllers[product['id']] = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300),
      );
      _colorAnimations[product['id']] = ColorTween(
        begin:
            themeNotifier.isSpecialModeActive
                ? themeNotifier
                    .getThemeColor(themeNotifier.specialTheme)
                    .shade400
                : Colors.red.shade400,
        end: Colors.grey.shade400,
      ).animate(_colorAnimationControllers[product['id']]!);
    }
    if (!_tickAnimationControllers.containsKey(product['id'])) {
      _tickAnimationControllers[product['id']] = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300),
      );
      _tickAnimations[product['id']] = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(_tickAnimationControllers[product['id']]!);
    }

    final animationController = _animationControllers[product['id']]!;

    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child:
                            (product["image"].startsWith('http') ||
                                    product["image"].startsWith('https'))
                                ? Image.network(
                                  product["image"],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'lib/assets/Images/placeholder.png',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                      ),
                                    );
                                  },
                                )
                                : Image.asset(
                                  product["image"],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                      color: Colors.grey[400],
                                    );
                                  },
                                ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: GestureDetector(
                          onTap: () => removeFromFavorites(product['id']),
                          child: Icon(
                            // Show hollow heart if product is marked as unfavorited
                            _unfavoritedProducts[product['id']] == true
                                ? Icons.favorite_border
                                : Icons.favorite,
                            color:
                                themeNotifier.isSpecialModeActive
                                    ? themeNotifier.getThemeColor(
                                      themeNotifier.specialTheme,
                                    )
                                    : Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 3,
              child: Container(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product["name"],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      _priceFormat.format(double.tryParse(product["price"]) ?? 0),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < ((product['averageRating'] ?? 0) as num).round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 12,
                          );
                        }),
                        SizedBox(width: 2),
                        Text(
                          '(${product['ratingCount'] ?? 0})',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Spacer(flex: 1),
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _colorAnimationControllers[product['id']]!,
                          _tickAnimationControllers[product['id']]!,
                        ]),
                        builder: (context, child) {
                          return ElevatedButton(
                            onPressed:
                                isOutOfStock ? null : () => addToCart(product),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _colorAnimations[product['id']]?.value ??
                                  (themeNotifier.isSpecialModeActive
                                      ? themeNotifier
                                          .getThemeColor(
                                            themeNotifier.specialTheme,
                                          )
                                          .shade400
                                      : Colors.red.shade400),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Opacity(
                                  opacity:
                                      1.0 -
                                      (_colorAnimationControllers[product['id']]
                                              ?.value ??
                                          0.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        isOutOfStock
                                            ? l10n.outOfStock
                                            : l10n.addToCart,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if ((_colorAnimationControllers[product['id']]
                                            ?.value ??
                                        0.0) >
                                    0)
                                  Transform.scale(
                                    scale:
                                        _tickAnimations[product['id']]?.value ??
                                        0.0,
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
