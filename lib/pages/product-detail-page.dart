import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/pages/cart_page.dart';
import 'package:intl/intl.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({Key? key, required this.productId})
    : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  Map<String, dynamic>? productData;
  bool isLoading = true;
  int quantity = 1;
  int selectedImageIndex = 0;
  int availableStock = 0;
  bool isFavorite = false;

  // Yeni eklenen değişkenler
  int _rating = 0;
  double? averageRating;
  int totalRatings = 0;

  late AnimationController _colorAnimationController;
  late Animation<Color?> _colorAnimation;
  late AnimationController _tickAnimationController;
  late Animation<double> _tickAnimation;
  bool _isAddingToCart = false;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _colorAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _colorAnimation = ColorTween(
      begin: Colors.red.shade400,
      end: Colors.green.shade500,
    ).animate(_colorAnimationController);

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

    fetchProductDetails();
    checkIfFavorite();
  }

  @override
  void dispose() {
    _colorAnimationController.dispose();
    _tickAnimationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> fetchProductDetails() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('products')
              .doc(widget.productId)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        final stockValue = data['stock'];
        final stock = stockValue is int ? stockValue : 0;

        if (mounted) {
          setState(() {
            productData = data;
            availableStock = stock;
            isLoading = false;
          });
        }

        // Yorumları ve ortalama puanı çek
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
      print("❌ Error fetching product: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> checkIfFavorite() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('favorites')
              .doc(user.uid)
              .collection('userFavorites')
              .doc(widget.productId)
              .get();

      if (mounted) {
        setState(() {
          isFavorite = docSnapshot.exists;
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please log in to add favorites')));
      return;
    }

    try {
      final favRef = FirebaseFirestore.instance
          .collection('favorites')
          .doc(user.uid)
          .collection('userFavorites')
          .doc(widget.productId);

      if (isFavorite) {
        await favRef.delete();
        if (mounted) {
          setState(() {
            isFavorite = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed from favorites'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await favRef.set({
          'name': productData?['name'] ?? 'Unknown Product',
          'price': productData?['price']?.toString() ?? '0',
          'image':
              productData?['imagePath'] ?? 'lib/assets/Images/placeholder.png',
          'category': productData?['category'] ?? 'Uncategorized',
          'description':
              productData?['description'] ?? 'No description available',
          'stock': availableStock,
          'addedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          setState(() {
            isFavorite = true;
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

  void incrementQuantity() {
    setState(() {
      if (quantity < availableStock && quantity < 10) quantity++;
    });
  }

  void decrementQuantity() {
    setState(() {
      if (quantity > 1) quantity--;
    });
  }

  Future<void> addToCart() async {
    if (_isAddingToCart) return;

    if (availableStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sorry, this product is out of stock')),
      );
      return;
    }

    if (quantity > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot add more than available stock ($availableStock)',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    _colorAnimationController.forward();
    await Future.delayed(Duration(milliseconds: 200));
    _tickAnimationController.forward();

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to add to cart')),
      );
      _resetAnimations();
      return;
    }

    final cartRef = FirebaseFirestore.instance
        .collection('cart')
        .doc(user.uid)
        .collection('userCart')
        .doc(widget.productId);

    try {
      final existingItem = await cartRef.get();

      if (existingItem.exists) {
        final prevQuantity = existingItem['quantity'] ?? 1;

        if (prevQuantity + quantity > availableStock) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cannot add more than available stock ($availableStock)',
                ),
              ),
            );
          }
          _resetAnimations();
          return;
        }

        await cartRef.update({'quantity': prevQuantity + quantity});
      } else {
        await cartRef.set({
          'productId': widget.productId,
          'name': productData?['name'],
          'price': productData?['price'],
          'imagePath': productData?['imagePath'],
          'quantity': quantity,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) {
        _resetAnimations();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${productData?['name']} x$quantity added to cart'),
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

      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        _resetAnimations();
      }
    } catch (e) {
      print('❌ Error adding to cart: $e');
      _resetAnimations();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add to cart')));
      }
    }
  }

  Future<void> submitComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please log in to add a comment')));
      return;
    }

    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Comment cannot be empty')));
      return;
    }

    try {
      // Add the new comment
      final commentsRef = FirebaseFirestore.instance
          .collection('comments')
          .doc(widget.productId)
          .collection('userComments');
      final commentRef = commentsRef.doc();
      await commentRef.set({
        'userId': user.uid,
        'userName': user.displayName ?? 'User',
        'comment': commentText,
        'rating': _rating,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('DEBUG: Comment added for product ${widget.productId}');

      // Update products collection
      final productRef = FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);
        if (!snapshot.exists) {
          print('DEBUG: Product document does not exist');
          return;
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final currentAvg = (data['averageRating'] ?? 0.0) as double;
        final currentCount = (data['ratingCount'] ?? 0) as int;
        print(
          'DEBUG: Current ratingCount: $currentCount, averageRating: $currentAvg',
        );

        // Fetch all comments to count total comments and calculate average rating
        final allCommentsSnapshot = await commentsRef.get();
        final ratings =
            allCommentsSnapshot.docs
                .map((doc) => (doc.data()['rating'] ?? 0) as int)
                .where((r) => r > 0)
                .toList();

        int newCount = allCommentsSnapshot.docs.length; // Count all comments
        double newAvg = currentAvg;

        if (_rating > 0 && ratings.isNotEmpty) {
          final total = ratings.reduce((a, b) => a + b);
          newAvg = total / ratings.length;
        }

        print('DEBUG: New ratingCount: $newCount, new averageRating: $newAvg');

        transaction.update(productRef, {
          'averageRating':
              _rating > 0
                  ? double.parse(newAvg.toStringAsFixed(1))
                  : currentAvg,
          'ratingCount': newCount,
        });
      });
      print('DEBUG: Transaction completed for product ${widget.productId}');

      if (mounted) {
        _commentController.clear();
        setState(() {
          _rating = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment added successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        await fetchProductDetails();
      }
    } catch (e) {
      print('Error adding comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add comment')));
      }
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
    if (timestamp == null) return 'Just now';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} minutes ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: Text(
            "Loading...",
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
            "Error",
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ),
        body: Center(
          child: Text(
            "Product not found",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      );
    }

    final name = productData!['name'] ?? 'Unknown';
    final price = productData!['price']?.toString() ?? '0';
    final imagePath = productData!['imagePath'] ?? '';
    final category = productData!['category'] ?? 'Uncategorized';
    final description =
        productData!['description'] ?? 'No description available.';
    final List<String> images =
        (productData!['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

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
          IconButton(
            icon: Icon(
              Icons.favorite,
              color:
                  isFavorite
                      ? Colors.red
                      : Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            onPressed: toggleFavorite,
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
        onRefresh: fetchProductDetails,
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
                        images[selectedImageIndex],
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
                        onTap: () => setState(() => selectedImageIndex = index),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 6),
                          width: 70,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  selectedImageIndex == index
                                      ? Theme.of(context).primaryColor
                                      : isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).cardColor,
                            boxShadow:
                                selectedImageIndex == index && !isDark
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
                      // Ortalama puan gösterme
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
                              "$averageRating ($totalRatings değerlendirme)",
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
                                ? "Out of Stock"
                                : "In Stock: $availableStock available",
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
                              "Quantity",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.color,
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
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
                                    color: Colors.grey.shade100,
                                    child: InkWell(
                                      onTap: decrementQuantity,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(7),
                                        bottomLeft: Radius.circular(7),
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(Icons.remove, size: 16),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      '$quantity',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Material(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(7),
                                      bottomRight: Radius.circular(7),
                                    ),
                                    color: Colors.grey.shade100,
                                    child: InkWell(
                                      onTap: incrementQuantity,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(7),
                                        bottomRight: Radius.circular(7),
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(Icons.add, size: 16),
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
                                                    : addToCart,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  _colorAnimation.value ??
                                                  Colors.red.shade400,
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
                                                        "ADD TO CART",
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
                        "Product Description",
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
              if (productData!['specifications'] != null)
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
                          "Specifications",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          productData!['specifications'].toString(),
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
              // Yorum gönderme kutusu
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
                        "Yorum Yap",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Ürünü puanlayın ve deneyiminizi paylaşın:",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: "Yorumunuzu buraya yazın...",
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          filled: true,
                          fillColor:
                              isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        maxLines: 4,
                      ),
                      SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: submitComment,
                          icon: Icon(Icons.send, size: 18),
                          label: Text("Gönder"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Yorumlar bölümü
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
                        "Comments",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      SizedBox(height: 12),
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
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Text(
                              'Error loading comments',
                              style: TextStyle(color: Colors.red),
                            );
                          }
                          final comments = snapshot.data?.docs ?? [];
                          if (comments.isEmpty) {
                            return Center(
                              child: Text(
                                'No comments yet',
                                style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            separatorBuilder:
                                (context, index) => Divider(height: 16),
                            itemBuilder: (context, index) {
                              final comment =
                                  comments[index].data()
                                      as Map<String, dynamic>;
                              final userName = comment['userName'] ?? 'User';
                              final commentText = comment['comment'] ?? '';
                              final timestamp =
                                  comment['timestamp'] as Timestamp?;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        userName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleLarge?.color,
                                        ),
                                      ),
                                      Text(
                                        _formatTimestamp(timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    commentText,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  if ((comment['rating'] ?? 0) > 0)
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < (comment['rating'] ?? 0)
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 18,
                                        );
                                      }),
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
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

extension on TextEditingController {
  void dispose() {}
}
