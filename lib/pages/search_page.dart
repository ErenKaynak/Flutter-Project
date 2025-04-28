import 'package:engineering_project/pages/root_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/pages/product-detail-page.dart';
import 'package:engineering_project/pages/cart_page.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';

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
  final Map<String, AnimationController> _animationControllers = {};

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  @override
  void dispose() {
    _animationControllers.forEach((_, controller) {
      controller.dispose();
    });
    _animationControllers.clear();
    super.dispose();
  }

  void _initializeAnimationControllers() {
    _animationControllers.forEach((_, controller) {
      controller.dispose();
    });
    _animationControllers.clear();

    for (var product in favoriteProducts) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 2),
      );
      _animationControllers[product['id']] = controller;
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
      favoritesSnapshot.docs.forEach((doc) {
        final data = doc.data();
        loadedFavorites.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Product',
          'price': data['price']?.toString() ?? '0',
          'image': data['image'] ?? 'lib/assets/Images/placeholder.png',
          'category': data['category'] ?? 'Uncategorized',
          'description': data['description'] ?? 'No description available',
          'stock': data['stock'] ?? 0,
        });
      });

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
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      await FirebaseFirestore.instance
          .collection('favorites')
          .doc(user.uid)
          .collection('userFavorites')
          .doc(productId)
          .delete();

      setState(() {
        favoriteProducts.removeWhere((product) => product['id'] == productId);
      });

      if (widget.onFavoritesChanged != null) {
        widget.onFavoritesChanged!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from favorites'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error removing from favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove from favorites'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> addToCart(Map<String, dynamic> product) async {
    final controller = _animationControllers[product['id']];
    if (controller != null && mounted) {
      controller.reset();
      await controller.forward();
      controller.reset();
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to add items to cart'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final cartRef = FirebaseFirestore.instance
          .collection('cart')
          .doc(user.uid)
          .collection('userCart')
          .doc(product['id']);

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
          content: Text('${product["name"]} added to cart'),
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      print('Error adding item to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item to cart'),
          duration: Duration(seconds: 2),
        ),
      );
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "My Favorites",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (!_isLoading && favoriteProducts.isNotEmpty)
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: fetchFavorites,
                tooltip: 'Refresh',
              ),
          ],
        ),
        body:
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : favoriteProducts.isEmpty
                ? _buildEmptyFavorites()
                : _buildFavoritesList(),
      ),
    );
  }

  Widget _buildEmptyFavorites() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
          SizedBox(height: 1),
          Text(
            "No favorites yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 1),
          Text(
            "Items you mark as favorite will appear here",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          SizedBox(height: 1),
          ElevatedButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RootScreen()),
                ),
            child: Text("Explore Products"),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              foregroundColor: Colors.white,
              backgroundColor:
                  themeNotifier.isBlackMode
                      ? Theme.of(context).colorScheme.secondary
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
          childAspectRatio: 0.65,
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    // Initialize animation controller if it doesn't exist
    if (!_animationControllers.containsKey(product['id'])) {
      _animationControllers[product['id']] = AnimationController(
        vsync: this,
        duration: Duration(seconds: 2),
      );
    }

    final animationController = _animationControllers[product['id']]!;

    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
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
                              Icons.favorite,
                              color:
                                  themeNotifier.isBlackMode
                                      ? Theme.of(context).colorScheme.secondary
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
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product["name"],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1),
                      Text(
                        "₺${product["price"]}",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 1),
                      SizedBox(
                        width: double.infinity,
                        height: 40, // Set a fixed height for the entire row
                        child:
                            isOutOfStock
                                ? Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color:
                                        themeNotifier.isBlackMode
                                            ? Colors.grey.shade50
                                            : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          themeNotifier.isBlackMode
                                              ? Theme.of(
                                                context,
                                              ).colorScheme.secondary
                                              : Colors.red.shade200,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Out of Stock",
                                      style: TextStyle(
                                        color:
                                            themeNotifier.isBlackMode
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.secondary
                                                : Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                                : GestureDetector(
                                  onTap: () => addToCart(product),
                                  child: Lottie.asset(
                                    'lib/assets/button-test/3.json',
                                    controller: animationController,
                                    fit: BoxFit.cover,
                                    width: 200,
                                    height: 50,
                                    repeat: false,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
