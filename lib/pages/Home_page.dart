import 'package:engineering_project/pages/cart_page.dart' as CartPage;
import 'package:engineering_project/pages/product-detail-page.dart';
import 'package:engineering_project/pages/search_page.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  List<Map<String, dynamic>> categories = [];
  bool _isLoading = true;
  List<String> favoriteProductIds = []; // Store only product IDs for favorites
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
  String _userName = "Guest"; // Default user name

  @override
  void initState() {
    super.initState();
    _cartManager.loadCart();
    _cartManager.addListener(_updateUI);
    _getUserProfile(); // Get current user name
    _loadCategories();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });

    _loadInitialData();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .get();

      if (mounted) {
        setState(() {
          categories = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unnamed Category',
              'iconPath': data['iconPath'] ?? '',
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // First fetch products
      await fetchProducts();

      // Then fetch favorites
      await fetchFavorites();

      // Finally update loading state if still mounted
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error loading initial data: $error');
      // Ensure loading indicator is removed even if there's an error
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

    // Dispose all animation controllers
    _colorAnimationControllers.forEach((_, controller) => controller.dispose());
    _tickAnimationControllers.forEach((_, controller) => controller.dispose());

    super.dispose();
  }

  // Fetch current user name from Firestore
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
      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Get profile image URL from Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user.uid}.jpg');

      String imageUrl;
      try {
        imageUrl = await storageRef.getDownloadURL();
      } catch (e) {
        print('Error getting profile image: $e');
        imageUrl = ''; // Set empty if image doesn't exist
      }

      if (mounted) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? 'User';
          _userProfilePicture = imageUrl.isNotEmpty ? imageUrl : null;
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

  void _initializeAnimationControllers() {
    // Dispose existing controllers
    _colorAnimationControllers.forEach((_, controller) => controller.dispose());
    _tickAnimationControllers.forEach((_, controller) => controller.dispose());
    _colorAnimationControllers.clear();
    _colorAnimations.clear();
    _tickAnimationControllers.clear();
    _tickAnimations.clear();
    _isAddingToCartMap.clear();

    // Only create new controllers if the widget is still mounted
    if (!mounted) return;

    for (var product in products) {
      final productId = product['id'];

      // Color animation controller
      final colorController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300),
      );
      _colorAnimationControllers[productId] = colorController;

      // Color animation
      _colorAnimations[productId] = ColorTween(
        begin: Colors.red.shade400,
        end: Colors.green.shade500,
      ).animate(colorController);

      // Tick animation controller
      final tickController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500),
      );
      _tickAnimationControllers[productId] = tickController;

      // Tick animation
      _tickAnimations[productId] = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: tickController,
        curve: Curves.elasticOut,
      ));

      _isAddingToCartMap[productId] = false;
    }
  }

  Future<void> fetchProducts() async {
    if (!mounted) return;

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
        // Don't set _isLoading = false here
      });

      _initializeAnimationControllers();
    } catch (error) {
      print('Error fetching products: $error');
      // Don't set _isLoading = false here either
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
            // Don't set _isLoading = false here
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
          // Don't set _isLoading = false here
        });
      }
    } catch (error) {
      print('Error fetching favorites: $error');
      // Don't set _isLoading = false here
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

  Future<void> _addToCart(Map<String, dynamic> product) async {
    if (_isAddingToCartMap[product['id']] == true) return;

    _isAddingToCartMap[product['id']] = true;

    // Start animations
    _colorAnimationControllers[product['id']]?.forward();
    await Future.delayed(Duration(milliseconds: 200));
    _tickAnimationControllers[product['id']]?.forward();

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
                    MaterialPageRoute(builder: (context) => CartPage.CartPage()),
                  );
                }
              },
            ),
          ),
        );
      }

      // Reset animations after success
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        _resetAnimations(product['id']);
      }
    } catch (e) {
      print('Error adding item to cart: $e');
      _resetAnimations(product['id']);
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

  void _resetAnimations(String productId) {
    final colorController = _colorAnimationControllers[productId];
    final tickController = _tickAnimationControllers[productId];

    if (colorController?.isAnimating ?? false) {
      colorController?.stop();
    }
    if (tickController?.isAnimating ?? false) {
      tickController?.stop();
    }
    colorController?.reset();
    tickController?.reset();

    if (mounted) {
      setState(() {
        _isAddingToCartMap[productId] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(15),
            ),
          ),
          elevation: 10,
          title: Container(
            height: 40,
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: "Search products",
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
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                  icon: Icon(Icons.shopping_cart),
                  onPressed: () {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CartPage.CartPage()),
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
            SizedBox(width: 20,)
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadInitialData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Welcome section with user name and person icon
                         Container(
  padding: EdgeInsets.all(16.0),
  margin: EdgeInsets.all(10.0),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: Theme.of(context).brightness == Brightness.dark
          ? [Colors.red.shade900, Colors.grey.shade900]
          : [Colors.red.shade500, Colors.red.shade100],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Theme.of(context).brightness == Brightness.dark
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
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.red.shade700
            : Colors.red.shade300,
        backgroundImage: _userProfilePicture != null 
            ? NetworkImage(_userProfilePicture!)
            : null,
        child: _userProfilePicture == null
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome",
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.black54,
              ),
            ),
            Text(
              _userName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
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

  Widget _buildBannerSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.blue.shade100,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black26
                : Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [Colors.red.shade900, Colors.black54]
                      : [Colors.red.shade500, Colors.red.shade100],
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
                    child: Text('Shop Now',
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.red,),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade900
                          : Colors.white,
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
        PopupMenuButton<String>(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort, size: 20, color: Colors.red.shade700),
              SizedBox(width: 4),
              Text(
                "Sort",
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          onSelected: (String value) {
            setState(() {
              switch (value) {
                case 'price_asc':
                  products.sort((a, b) => double.parse(a["price"].toString())
                      .compareTo(double.parse(b["price"].toString())));
                  break;
                case 'price_desc':
                  products.sort((a, b) => double.parse(b["price"].toString())
                      .compareTo(double.parse(a["price"].toString())));
                  break;
                case 'name_asc':
                  products.sort((a, b) => 
                      a["name"].toString().compareTo(b["name"].toString()));
                  break;
                case 'name_desc':
                  products.sort((a, b) => 
                      b["name"].toString().compareTo(a["name"].toString()));
                  break;
              }
            });
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'price_asc',
              child: Row(
                children: [
                  Icon(Icons.arrow_upward, size: 20),
                  SizedBox(width: 8),
                  Text('Price: Low to High'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'price_desc',
              child: Row(
                children: [
                  Icon(Icons.arrow_downward, size: 20),
                  SizedBox(width: 8),
                  Text('Price: High to Low'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'name_asc',
              child: Row(
                children: [
                  Icon(Icons.sort_by_alpha, size: 20),
                  SizedBox(width: 8),
                  Text('Name: A to Z'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'name_desc',
              child: Row(
                children: [
                  Icon(Icons.sort_by_alpha, size: 20),
                  SizedBox(width: 8),
                  Text('Name: Z to A'),
                ],
              ),
            ),
          ],
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
        // First add dynamic categories
        ...categories.map((category) => Row(
          children: [
            _buildCategoryCircle(
              category['name'],
              category['iconPath'],
              _selectedCategory == category['name'],
              () => _selectCategory(category['name']),
              false, // isAsset = false for network image
            ),
            SizedBox(width: 15),
          ],
        )).toList(),
        // Add "Show All" category last
        _buildCategoryCircle(
          "All",
          'lib/assets/Images/all-icon.png',
          _selectedCategory == "All",
          () => _selectCategory("All"),
          true, // isAsset = true for local asset
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
  bool isAsset, // Add this parameter
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? (isSelected ? Colors.red.shade900 : Colors.grey.shade800)
                : (isSelected ? Colors.red.shade50 : Colors.grey.shade200),
            border: isSelected
                ? Border.all(color: isDark ? Colors.red.shade700 : Colors.red.shade400, width: 2)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: isDark
                          ? Colors.red.shade900.withOpacity(0.5)
                          : Colors.red.shade300.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          padding: EdgeInsets.all(10),
          child: isAsset
              ? Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  color: isDark ? Colors.white70 : null,
                )
              : Image.network(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading category image: $error');
                    return Icon(Icons.category, 
                      color: isDark ? Colors.white70 : Colors.grey,
                    );
                  },
                ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isDark
                ? (isSelected ? Colors.red.shade400 : Colors.white70)
                : (isSelected ? Colors.red : Colors.black),
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
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.white,
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade900
                        : Colors.grey[200],
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
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            _colorAnimationControllers[product['id']]!,
                            _tickAnimationControllers[product['id']]!
                          ]),
                          builder: (context, child) {
                            return ElevatedButton(
                              onPressed: isOutOfStock || _isAddingToCartMap[product['id']] == true
                                  ? null
                                  : () => _addToCart(product),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _colorAnimations[product['id']]?.value ?? Colors.red.shade400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Opacity(
                                    opacity: 1.0 - (_colorAnimationControllers[product['id']]?.value ?? 0.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (!isOutOfStock) Icon(Icons.shopping_cart, size: 16),
                                        if (!isOutOfStock) SizedBox(width: 8),
                                        Text(
                                          isOutOfStock ? "OUT OF STOCK" : "ADD TO CART",
                                          style: TextStyle(
                                            fontSize: isOutOfStock ? 12 : 14,  // Smaller font for OUT OF STOCK
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,  // Ensure single line
                                          overflow: TextOverflow.visible,  // Handle overflow
                                        ),
                                      ],
                                    ),
                                  ),
                                  if ((_colorAnimationControllers[product['id']]?.value ?? 0.0) > 0)
                                    Transform.scale(
                                      scale: _tickAnimations[product['id']]?.value ?? 0.0,
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
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  final Function onFavoritesChanged;

  FavoritesPage({required this.onFavoritesChanged});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          favorites = [];
          _isLoading = false;
        });
        return;
      }

      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .doc(user.uid)
          .collection('userFavorites')
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
        favorites = loadedFavorites;
        _isLoading = false;
      });
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
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('favorites')
          .doc(user.uid)
          .collection('userFavorites')
          .doc(productId)
          .delete();

      setState(() {
        favorites.removeWhere((product) => product['id'] == productId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from favorites'),
          duration: Duration(seconds: 2),
        ),
      );

      widget.onFavoritesChanged();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Favorites'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 70, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No favorites yet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Items you favorite will appear here",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final product = favorites[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (product["image"].startsWith('http') ||
                                  product["image"].startsWith('https'))
                              ? Image.network(
                                  product["image"],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'lib/assets/Images/placeholder.png',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  product["image"],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.image_not_supported,
                                      size: 30,
                                    );
                                  },
                                ),
                        ),
                        title: Text(
                          product["name"],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("₺${product["price"]}"),
                        trailing: IconButton(
                          icon: Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => removeFromFavorites(product["id"]),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(
                                productId: product["id"],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

// CartManager class to handle cart operations
class CartManager extends ChangeNotifier {
  List<CartItem> _items = [];
  
  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  void addItem(CartItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(item);
    }
    notifyListeners();
    saveCart();
  }
  
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    saveCart();
  }
  
  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
      saveCart();
    }
  }
  
  void clear() {
    _items.clear();
    notifyListeners();
    saveCart();
  }
  
  Future<void> loadCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cart')
          .doc(user.uid)
          .collection('userCart')
          .get();
      
      _items = snapshot.docs.map((doc) {
        final data = doc.data();
        return CartItem(
          id: doc.id,
          name: data['name'] ?? 'Unknown Product',
          price: double.tryParse(data['price']?.toString() ?? '0') ?? 0.0,
          imagePath: data['imagePath'] ?? 'lib/assets/Images/placeholder.png',
          quantity: data['quantity'] ?? 1,
        );
      }).toList();
      
      notifyListeners();
    } catch (e) {
      print('Error loading cart: $e');
    }
  }
  
  Future<void> saveCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final batch = FirebaseFirestore.instance.batch();
      final cartRef = FirebaseFirestore.instance
          .collection('cart')
          .doc(user.uid)
          .collection('userCart');
      
      // First, delete all existing items
      final existingItems = await cartRef.get();
      for (var doc in existingItems.docs) {
        batch.delete(doc.reference);
      }
      
      // Then add current items
      for (var item in _items) {
        final docRef = cartRef.doc(item.id);
        batch.set(docRef, {
          'name': item.name,
          'price': item.price.toString(),
          'imagePath': item.imagePath,
          'quantity': item.quantity,
        });
      }
      
      await batch.commit();
    } catch (e) {
      print('Error saving cart: $e');
    }
  }
}

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imagePath;
  int quantity;
  
  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    this.quantity = 1,
  });
}