import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/pages/cart_page.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:engineering_project/models/localized_product.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/l10n/app_localizations.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({Key? key, required this.productId})
    : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  LocalizedProduct? productData;
  bool isLoading = true;
  int selectedQuantity = 1;
  int availableStock = 0;
  bool isFavorite = false;
  bool isCheckingFavorite = true;
  bool isOutOfStock = false;

  double? averageRating;
  int totalRatings = 0;

  late AnimationController _colorAnimationController;
  late Animation<Color?> _colorAnimation;
  late AnimationController _tickAnimationController;
  late Animation<double> _tickAnimation;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();

    _colorAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    // Initialize color animation with ThemeNotifier
    _colorAnimationController.addListener(() {
      if (mounted) setState(() {});
    });
    _tickAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _tickAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _tickAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _loadProductData();
    _checkFavoriteStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    _colorAnimation = ColorTween(
      begin:
          themeNotifier.isSpecialModeActive
              ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade400
              : Colors.red.shade400,
      end: Colors.green.shade500,
    ).animate(_colorAnimationController);
  }

  @override
  void dispose() {
    _colorAnimationController.dispose();
    _tickAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadProductData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (doc.exists) {
        // Add debug print for raw data
        print('Raw Firestore Data: ${doc.data()}');
        
        final localizedProduct = LocalizedProduct.fromFirestore(doc);
        
        if (mounted) {
          setState(() {
            productData = localizedProduct;
            availableStock = localizedProduct.stock;
            isOutOfStock = localizedProduct.stock <= 0;
            isLoading = false;
          });
        }

        // Fetch comments and average rating
        final commentsSnapshot =
            await FirebaseFirestore.instance
                .collection('comments')
                .doc(widget.productId)
                .collection('userComments')
                .get();

        if (commentsSnapshot.docs.isNotEmpty) {
          final ratings =
              commentsSnapshot.docs
                  .map((doc) => (doc.data()['rating'] ?? 0) as int)
                  .where((r) => r > 0)
                  .toList();

          if (ratings.isNotEmpty) {
            final total = ratings.reduce((a, b) => a + b);
            final avg = total / ratings.length;

            if (mounted) {
              setState(() {
                averageRating = double.parse(avg.toStringAsFixed(1));
                totalRatings = ratings.length;
              });
            }
          }
        }
      } else {
        throw Exception('Product does not exist');
      }
    } catch (e) {
      print("❌ Error loading product: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(widget.productId)
            .get();

        setState(() {
          isFavorite = doc.exists;
          isCheckingFavorite = false;
        });
      } catch (e) {
        print("❌ Error checking favorite status: $e");
        setState(() {
          isCheckingFavorite = false;
        });
      }
    } else {
      setState(() {
        isCheckingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseLoginToAdd)),
      );
      return;
    }

    try {
      final favoriteRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.productId);

      if (isFavorite) {
        await favoriteRef.delete();
        setState(() => isFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.removedFromFavorites)),
        );
      } else {
        await favoriteRef.set({
          'productId': widget.productId,
          'addedAt': FieldValue.serverTimestamp(),
        });
        setState(() => isFavorite = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addedToFavorites)),
        );
      }
    } catch (e) {
      print("❌ Error toggling favorite: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToUpdateFavorites)),
      );
    }
  }

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSignIn)),
      );
      return;
    }

    if (isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.outOfStock)),
      );
      return;
    }

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(widget.productId);

      final cartDoc = await cartRef.get();
      Map<String, dynamic>? cartData = cartDoc.exists ? cartDoc.data() as Map<String, dynamic> : null;
      final currentQuantity = cartData?['quantity'] as int? ?? 0;
      final newQuantity = currentQuantity + selectedQuantity;

      if (newQuantity > availableStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cannotAddMoreThanStock(availableStock)),
          ),
        );
        return;
      }

      await cartRef.set({
        'productId': widget.productId,
        'quantity': newQuantity,
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addedToCart(productData?.name ?? '')),
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
    } catch (e) {
      print("❌ Error adding to cart: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToAddToCart)),
      );
    }
  }

  void _resetAnimations() {
    if (_colorAnimationController.isAnimating) {
      _colorAnimationController.stop();
    }
    if (_tickAnimationController.isAnimating) {
      _tickAnimationController.stop();
    }
    _colorAnimationController.reset();
    _tickAnimationController.reset();
    if (mounted) {
      setState(() {
        _isAddingToCart = false;
      });
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    final l10n = AppLocalizations.of(context)!;
    if (timestamp == null) return l10n.loading;
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return l10n.loading;
    if (difference.inHours < 1) return l10n.minutesAgo(difference.inMinutes);
    if (difference.inDays < 1) return l10n.hoursAgo(difference.inHours);
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;

    // Add debug prints
    print('Current Locale: $currentLocale');
    if (productData != null) {
      print('Available Descriptions: ${productData!.descriptions.keys.toList()}');
      print('Selected Description: ${productData!.getDescription(currentLocale)}');
    }

    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: Text(
            l10n.loading,
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    if (productData == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: Text(
            l10n.productNotFound,
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ),
        body: Center(
          child: Text(
            l10n.productNotFound,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      );
    }

    final name = productData!.name;
    final price = productData!.price.toString();
    final imagePath = productData!.imageUrl;
    final category = productData!.category;
    final description = productData!.getDescription(currentLocale);
    final images = productData!.images;

    if (images.isEmpty) images.add(imagePath);

    final bool isOutOfStock = availableStock <= 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: isDark ? 0 : 2,
        title: Text(
          name,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        actions: [
          if (!isCheckingFavorite)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Theme.of(context).iconTheme.color,
              ),
              onPressed: _toggleFavorite,
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartPage()),
                  );
                },
              ),
            ],
          ),
          SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        color: Theme.of(context).primaryColor,
        onRefresh: _loadProductData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors:
                            isDark
                                ? [
                                  Colors.grey.shade900,
                                  Theme.of(context).scaffoldBackgroundColor,
                                ]
                                : [Colors.grey.shade200, Colors.white],
                      ),
                    ),
                    child: Hero(
                      tag: 'product-${widget.productId}',
                      child: Image.network(
                        images[selectedQuantity - 1],
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, __, ___) => Icon(
                              Icons.image_not_supported,
                              size: 100,
                              color: Colors.grey,
                            ),
                      ),
                    ),
                  ),
                  if (isOutOfStock)
                    Positioned(
                      top: 20,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'OUT OF STOCK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (images.length > 1)
                Container(
                  height: 80,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => setState(() => selectedQuantity = index + 1),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 6),
                          width: 70,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  selectedQuantity == index + 1
                                      ? Theme.of(context).primaryColor
                                      : isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).cardColor,
                            boxShadow:
                                selectedQuantity == index + 1 && !isDark
                                    ? [
                                      BoxShadow(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                    : null,
                          ),
                          padding: EdgeInsets.all(4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Icon(
                                    Icons.image_not_supported,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:
                      isDark
                          ? []
                          : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.color,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.green.shade900.withOpacity(0.3)
                                      : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isDark
                                        ? Colors.green.shade700
                                        : Colors.green.shade100,
                              ),
                            ),
                            child: Text(
                              '₺$price',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? Colors.green.shade400
                                        : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Display average rating
                      if (averageRating != null)
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < averageRating!.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              );
                            }),
                            SizedBox(width: 6),
                            Text(
                              "$averageRating (${AppLocalizations.of(context)!.ratingCount(totalRatings)})",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOutOfStock ? Colors.red : Colors.green,
                            ),
                            width: 12,
                            height: 12,
                          ),
                          SizedBox(width: 8),
                          Text(
                            isOutOfStock
                                ? l10n.outOfStock
                                : l10n.inStock(availableStock),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isOutOfStock ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 32),
                      if (!isOutOfStock)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.productQuantity,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      isDark
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Material(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(7),
                                      bottomLeft: Radius.circular(7),
                                    ),
                                    color:
                                        isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade100,
                                    child: InkWell(
                                      onTap: selectedQuantity > 1
                                          ? () {
                                              setState(() {
                                                selectedQuantity--;
                                              });
                                            }
                                          : null,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(7),
                                        bottomLeft: Radius.circular(7),
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.remove,
                                          size: 16,
                                          color:
                                              isDark
                                                  ? Colors.grey.shade300
                                                  : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    color:
                                        isDark
                                            ? Colors.grey.shade900
                                            : Colors.white,
                                    child: Text(
                                      '$selectedQuantity',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDark
                                                ? Colors.grey.shade300
                                                : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  Material(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(7),
                                      bottomRight: Radius.circular(7),
                                    ),
                                    color:
                                        isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade100,
                                    child: InkWell(
                                      onTap: selectedQuantity < availableStock
                                          ? () {
                                              setState(() {
                                                selectedQuantity++;
                                              });
                                            }
                                          : null,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(7),
                                        bottomRight: Radius.circular(7),
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.add,
                                          size: 16,
                                          color:
                                              isDark
                                                  ? Colors.grey.shade300
                                                  : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child:
                                  isOutOfStock
                                      ? ElevatedButton(
                                        onPressed: null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.greenAccent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          "OUT OF STOCK",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                      : AnimatedBuilder(
                                        animation: Listenable.merge([
                                          _colorAnimationController,
                                          _tickAnimationController,
                                        ]),
                                        builder: (context, child) {
                                          return ElevatedButton(
                                            onPressed:
                                                _isAddingToCart
                                                    ? null
                                                    : _addToCart,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  _colorAnimation.value,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              elevation: 2,
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Opacity(
                                                  opacity:
                                                      1.0 -
                                                      _colorAnimationController
                                                          .value,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.shopping_cart,
                                                        size: 20,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        l10n.addToCart,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (_colorAnimationController
                                                        .value >
                                                    0)
                                                  Transform.scale(
                                                    scale: _tickAnimation.value,
                                                    child: Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 30,
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
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:
                      isDark
                          ? []
                          : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.productDescription,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (productData!.specifications != null)
                Container(
                  margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow:
                        isDark
                            ? []
                            : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.specifications,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          productData!.specifications!,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:
                      isDark
                          ? []
                          : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.customerReviews,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          if (averageRating != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? Colors.amber.shade900.withOpacity(0.2)
                                        : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      isDark
                                          ? Colors.amber.shade700
                                          : Colors.amber.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    averageRating!.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark
                                              ? Colors.amber.shade400
                                              : Colors.amber.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('comments')
                              .doc(widget.productId)
                              .collection('userComments')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(AppLocalizations.of(context)!.couldNotLoadReviews),
                            ),
                          );
                        }

                        final comments = snapshot.data?.docs ?? [];

                        if (comments.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.all(30),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.rate_review_outlined,
                                    size: 48,
                                    color:
                                        isDark
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context)!.noReviewsYet,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          isDark
                                              ? Colors.grey.shade500
                                              : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          itemCount: comments.length,
                          separatorBuilder:
                              (context, index) => Divider(
                                height: 40,
                                thickness: 1,
                                color:
                                    isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                              ),
                          itemBuilder: (context, index) {
                            final comment =
                                comments[index].data() as Map<String, dynamic>;
                            return FutureBuilder<DocumentSnapshot>(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(comment['userId'])
                                      .get(),
                              builder: (context, userSnapshot) {
                                final userData =
                                    userSnapshot.data?.data()
                                        as Map<String, dynamic>?;
                                final String fullName =
                                    userData != null
                                        ? "${userData['name'] ?? ''} ${userData['surname'] ?? ''}"
                                        : AppLocalizations.of(context)!.anonymous;
                                final String profilePicUrl =
                                    userData?['profileImageUrl'] ?? '';

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor:
                                              isDark
                                                  ? Colors.grey.shade800
                                                  : Colors.grey.shade200,
                                          backgroundImage:
                                              (profilePicUrl.isNotEmpty &&
                                                      profilePicUrl != "null")
                                                  ? NetworkImage(profilePicUrl)
                                                  : null,
                                          child:
                                              (profilePicUrl.isEmpty ||
                                                      profilePicUrl == "null")
                                                  ? Icon(
                                                    Icons.person,
                                                    color:
                                                        isDark
                                                            ? Colors
                                                                .grey
                                                                .shade600
                                                            : Colors
                                                                .grey
                                                                .shade400,
                                                    size: 28,
                                                  )
                                                  : null,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                fullName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color:
                                                      Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.color,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  ...List.generate(
                                                    5,
                                                    (index) => Padding(
                                                      padding: EdgeInsets.only(
                                                        right: 2,
                                                      ),
                                                      child: Icon(
                                                        index <
                                                                (comment['rating'] ??
                                                                    0)
                                                            ? Icons.star
                                                            : Icons.star_border,
                                                        size: 16,
                                                        color: Colors.amber,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    _formatTimestamp(
                                                      comment['timestamp']
                                                          as Timestamp?,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          isDark
                                                              ? Colors
                                                                  .grey
                                                                  .shade500
                                                              : Colors
                                                                  .grey
                                                                  .shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (comment['comment']?.isNotEmpty ??
                                        false) ...[
                                      SizedBox(height: 12),
                                      Text(
                                        comment['comment'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color:
                                              isDark
                                                  ? Colors.grey.shade300
                                                  : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
