import 'package:engineering_project/pages/cart_page.dart';
import 'package:engineering_project/pages/product-detail-page.dart';
import 'package:engineering_project/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String _selectedCategory = "All";
  List<Map<String, dynamic>> products = [];
  bool _isLoading = true;
  List<String> favoriteProductIds = []; // Store only product IDs for favorites
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final CartManager _cartManager = CartManager();
  final Map<String, AnimationController> _animationControllers = {};
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchFavorites(); // Fetch favorites on initialization
    _cartManager.loadCart();
    _cartManager.addListener(_updateUI);

    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  void _updateUI(List<CartItem> _) {
    if (mounted && !_isDisposed) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    _cartManager.removeListener(_updateUI);

    // Properly dispose of all animation controllers
    _animationControllers.forEach((_, controller) {
      controller.stop();
      controller.dispose();
    });
    _animationControllers.clear();

    super.dispose();
  }

  void _initializeAnimationControllers() {
    // Safely dispose of any existing controllers
    _animationControllers.forEach((_, controller) {
      controller.stop();
      controller.dispose();
    });
    _animationControllers.clear();

    // Only create new controllers if the widget is still mounted
    if (!mounted) return;

    for (var product in products) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 2),
      );
      _animationControllers[product['id']] = controller;
    }
  }

  Future<void> fetchProducts() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('products').get();

      final List<Map<String, dynamic>> loadedProducts = [];

      snapshot.docs.forEach((doc) {
        final data = doc.data() as Map<String, dynamic>;

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
        });
      });

      if (!mounted) return;
      
      setState(() {
        products = loadedProducts;
        _isLoading = false;
      });

      _initializeAnimationControllers();
    } catch (error) {
      print('Error fetching products: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fetch favorites from Firestore
  Future<void> fetchFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // If not logged in, can't have favorites
        if (mounted) {
          setState(() {
            favoriteProductIds = [];
          });
        }
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

  // Toggle favorite status of a product
  Future<void> toggleFavorite(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to add favorites'),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
        // Remove from favorites
        await favRef.delete();
        if (mounted) {
          setState(() {
            favoriteProductIds.remove(productId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed from favorites'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Add to favorites
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
              content: Text('Added to favorites'),
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
            content: Text('Failed to update favorites'),
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

  void _navigateToFavoritesPage() {
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FavoritesPage(
          onFavoritesChanged: () {
            // Refresh favorites when returning from favorites page
            fetchFavorites();
          },
        ),
      ),
    ).then((_) {
      // Refresh favorites when returning from favorites page
      if (mounted) {
        fetchFavorites();
      }
    });
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    final controller = _animationControllers[product['id']];
    if (controller != null && mounted && !_isDisposed) {
      controller.reset();
      try {
        await controller.forward();
        if (mounted && !_isDisposed) {
          controller.reset();
        }
      } catch (e) {
        print('Animation error: $e');
      }
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please log in to add items to cart'),
              duration: Duration(seconds: 2),
            ),
          );
        }
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
        await cartRef.update({
          'quantity': newQuantity,
        });
      } else {
        await cartRef.set({
          'name': product['name'],
          'price': product['price'],
          'imagePath': product['image'],
          'quantity': 1,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product["name"]} added to cart'),
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'VIEW CART',
              onPressed: () {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartPage()),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error adding item to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item to cart: $e'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Container(
            height: 40,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hoverColor: Colors.red,
                hintText: "Search products",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.search, size: 25),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                alignLabelWithHint: true,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
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
                  icon: Icon(Icons.shopping_cart),
                  onPressed: () {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CartPage()),
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
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
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
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: fetchProducts,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildCategoryButton(
                                  Icons.favorite, 
                                  "Favorites",
                                  onTap: _navigateToFavoritesPage,
                                ),
                                _buildCategoryButton(Icons.history, "History"),
                                _buildCategoryButton(Icons.person, "Following"),
                              ],
                            ),
                          ),
                          _buildBannerSection(),
                          SizedBox(height: 10),
                          _buildCategoriesHeader(),
                          _buildCategoriesRow(),
                          _buildProductsHeader(),
                        ],
                      ),
                    ),
                    _buildProductsGrid(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCategoryButton(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 24), SizedBox(width: 8), Text(label)],
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.blue.shade100,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade300, Colors.red.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Special Offers',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Get up to 20% off on selected products',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Shop Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesHeader() {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Categories",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {
              if (mounted) {
                setState(() {
                  _selectedCategory = "All";
                });
              }
            },
            child: Text("Show All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          _buildCategoryCircle(
            "GPU's",
            'lib/assets/Images/gpu-icon.png',
            _selectedCategory == "GPU's",
            () => _selectCategory("GPU's"),
          ),
          SizedBox(width: 15),
          _buildCategoryCircle(
            "Motherboards",
            'lib/assets/Images/motherboard-icon.png',
            _selectedCategory == "Motherboards",
            () => _selectCategory("Motherboards"),
          ),
          SizedBox(width: 15),
          _buildCategoryCircle(
            "CPU's",
            'lib/assets/Images/cpu-icon.png',
            _selectedCategory == "CPU's",
            () => _selectCategory("CPU's"),
          ),
          SizedBox(width: 15),
          _buildCategoryCircle(
            "RAM's",
            'lib/assets/Images/ram-icon.png',
            _selectedCategory == "RAM's",
            () => _selectCategory("RAM's"),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCircle(
    String label,
    String imagePath,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.red.shade50 : Colors.grey.shade200,
              border: isSelected
                  ? Border.all(color: Colors.red.shade400, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.red.shade200.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            padding: EdgeInsets.all(10),
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsHeader() {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _searchQuery.isNotEmpty
                ? "Search Results"
                : (_selectedCategory == "All"
                    ? "Best Deals"
                    : _selectedCategory),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            "${filteredProducts.length} products",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (filteredProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 70, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No products found",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? "Try a different search term"
                      : "Try selecting a different category",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(10),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 15,
          childAspectRatio: 0.6,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = filteredProducts[index];
          final int stock = product["stock"] is int ? product["stock"] : 0;
          final bool isOutOfStock = stock <= 0;
          final bool isFavorite = favoriteProductIds.contains(product['id']);
          
          // Create controller if it doesn't exist
          if (!_animationControllers.containsKey(product['id']) && mounted && !_isDisposed) {
            _animationControllers[product['id']] = AnimationController(
              vsync: this,
              duration: Duration(seconds: 2),
            );
          }

          final animationController = _animationControllers[product['id']];
          if (animationController == null) {
            // Fallback if controller is null
            return Container();
          }

          return _buildProductCard(
            product: product,
            isOutOfStock: isOutOfStock,
            isFavorite: isFavorite,
            animationController: animationController,
          );
        }, childCount: filteredProducts.length),
      ),
    );
  }

  Widget _buildProductCard({
    required Map<String, dynamic> product,
    required bool isOutOfStock,
    required bool isFavorite,
    required AnimationController animationController,
  }) {
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
                          child: (product["image"].startsWith('http') ||
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
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
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
                            onTap: () => toggleFavorite(product),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red,
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
                      SizedBox(height: 4),
                      Text(
                        "₺${product["price"]}",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: isOutOfStock
                            ? Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  "Out of Stock",
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : GestureDetector(
                                onTap: () => _addToCart(product),
                                child: SizedBox(
                                  child: Lottie.asset(
                                    'lib/assets/button-test/3.json',
                                    controller: animationController,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 20,
                                    repeat: false,
                                  ),
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