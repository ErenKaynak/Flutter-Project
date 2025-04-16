import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/pages/cart_page.dart';
import 'package:lottie/lottie.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({Key? key, required this.productId}) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> with TickerProviderStateMixin {
  Map<String, dynamic>? productData;
  bool isLoading = true;
  int quantity = 1;
  int selectedImageIndex = 0;
  int availableStock = 0;
  bool isFavorite = false;
  late AnimationController _addToCartController;

  @override
  void initState() {
    super.initState();
    fetchProductDetails();
    checkIfFavorite();
    
    _addToCartController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _addToCartController.dispose();
    super.dispose();
  }

  Future<void> fetchProductDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get the stock value from the product data
        final stockValue = data['stock'];
        final stock = stockValue is int ? stockValue : 0;
        
        setState(() {
          productData = data;
          availableStock = stock;
          isLoading = false;
        });
      } else {
        throw Exception('Product does not exist');
      }
    } catch (e) {
      print("❌ Error fetching product: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> checkIfFavorite() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .doc(user.uid)
          .collection('userFavorites')
          .doc(widget.productId)
          .get();

      setState(() {
        isFavorite = docSnapshot.exists;
      });
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to add favorites')),
      );
      return;
    }

    try {
      final favRef = FirebaseFirestore.instance
          .collection('favorites')
          .doc(user.uid)
          .collection('userFavorites')
          .doc(widget.productId);

      if (isFavorite) {
        // Remove from favorites
        await favRef.delete();
        setState(() {
          isFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from favorites'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        // Add to favorites
        await favRef.set({
          'name': productData?['name'] ?? 'Unknown Product',
          'price': productData?['price']?.toString() ?? '0',
          'image': productData?['imagePath'] ?? 'lib/assets/Images/placeholder.png',
          'category': productData?['category'] ?? 'Uncategorized',
          'description': productData?['description'] ?? 'No description available',
          'stock': availableStock,
          'addedAt': FieldValue.serverTimestamp(),
        });
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
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorites'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void incrementQuantity() {
    setState(() {
      // Only allow increasing quantity if it's less than available stock and less than 10
      if (quantity < availableStock && quantity < 10) quantity++;
    });
  }

  void decrementQuantity() {
    setState(() {
      if (quantity > 1) quantity--;
    });
  }

  Future<void> addToCart() async {
    _addToCartController.reset();
    _addToCartController.forward();
    
    // If the product is out of stock, don't proceed
    if (availableStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sorry, this product is out of stock')),
      );
      return;
    }
    
    // Check if the requested quantity exceeds available stock
    if (quantity > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot add more than available stock ($availableStock)')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to add to cart')),
      );
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
        
        // Check if the combined quantity exceeds available stock
        if (prevQuantity + quantity > availableStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot add more than available stock ($availableStock)')),
          );
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

      if (!mounted) return;

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
    } catch (e) {
      print('❌ Error adding to cart: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to cart')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Loading...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (productData == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Error")),
        body: Center(child: Text("Product not found")),
      );
    }

    final name = productData!['name'] ?? 'Unknown';
    final price = productData!['price']?.toString() ?? '0';
    final imagePath = productData!['imagePath'] ?? '';
    final category = productData!['category'] ?? 'Uncategorized';
    final description = productData!['description'] ?? 'No description available.';
    final List<String> images = (productData!['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    if (images.isEmpty) images.add(imagePath);

    // Check if product is out of stock
    final bool isOutOfStock = availableStock <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite, color: isFavorite ? Colors.red : Colors.grey),
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
              // Add cart counter badge here if you have a cartItemCount
              // Positioned(...)
            ],
          ),
          SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchProductDetails,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image with gradient overlay
              Stack(
                children: [
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.grey.shade200, Colors.white],
                      ),
                    ),
                    child: Hero(
                      tag: 'product-${widget.productId}',
                      child: Image.network(
                        images[selectedImageIndex],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Out of Stock ribbon
                  if (isOutOfStock)
                    Positioned(
                      top: 20,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
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

              // Image thumbnails
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
                              color: selectedImageIndex == index 
                                  ? Colors.red.shade400 
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                            boxShadow: selectedImageIndex == index 
                              ? [
                                  BoxShadow(
                                    color: Colors.red.shade300.withOpacity(0.3),
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
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Product information card
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
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
                      // Product Name and Price
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
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: Text(
                              '₺$price',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Category
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      
                      // Availability
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
                      
                      // Quantity Control
                      if (!isOutOfStock)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Quantity",
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
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
                                    padding: EdgeInsets.symmetric(horizontal: 16),
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
                            
                            // Add to Cart Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: isOutOfStock
                              ? ElevatedButton(
                                  onPressed: null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
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
                              : GestureDetector(
                                  onTap: addToCart,
                                  child: SizedBox(
                                    child: Lottie.asset(
                                      'lib/assets/button-test/3.json',
                                      controller: _addToCartController,
                                      fit: BoxFit.cover,
                                      repeat: false,
                                    ),
                                  ),
                                ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              // Description Card
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
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
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Specifications Card (if available)
              if (productData!['specifications'] != null)
                Container(
                  margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
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
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        // Add specifications details here if available
                        Text(
                          productData!['specifications'].toString(),
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.black87,
                          ),
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