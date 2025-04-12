import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/pages/cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({Key? key, required this.productId}) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Map<String, dynamic>? productData;
  bool isLoading = true;
  int quantity = 1;
  int selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchProductDetails();
  }

  Future<void> fetchProductDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (doc.exists) {
        setState(() {
          productData = doc.data();
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

  void incrementQuantity() {
    setState(() {
      if (quantity < 10) quantity++;
    });
  }

  void decrementQuantity() {
    setState(() {
      if (quantity > 1) quantity--;
    });
  }

  Future<void> addToCart() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to add to cart')),
      );
      return;
    }

    print('🧪 addToCart() started');
    print('👤 User UID: ${user.uid}');
    print('📦 Product Data: $productData');

    final cartRef = FirebaseFirestore.instance
        .collection('cart')
        .doc(user.uid)
        .collection('userCart')
        .doc(widget.productId);

    try {
      final existingItem = await cartRef.get();

      if (existingItem.exists) {
        final prevQuantity = existingItem['quantity'] ?? 1;
        await cartRef.update({'quantity': prevQuantity + quantity});
        print('📝 Cart updated with new quantity: ${prevQuantity + quantity}');
      } else {
        await cartRef.set({
          'productId': widget.productId,
          'name': productData?['name'],
          'price': productData?['price'], // Store as string
          'imagePath': productData?['imagePath'],
          'quantity': quantity,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('🆕 Product added to cart');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${productData?['name']} x$quantity added to cart')),
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
    final description =
        productData!['description'] ?? 'No description available.';
    final List<String> images = (productData!['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    if (images.isEmpty) images.add(imagePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: Image.network(
                images[selectedImageIndex],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
              ),
            ),

            // Image thumbnails
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => setState(() => selectedImageIndex = index),
                    child: Container(
                      margin: EdgeInsets.all(8),
                      width: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              selectedImageIndex == index ? Colors.red : Colors.grey,
                          width: 2,
                        ),
                        color: Colors.grey[200],
                      ),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Product info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style:
                                  TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text("Category: $category",
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Text(
                        '₺$price',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Quantity
                  Row(
                    children: [
                      Text(
                        "Quantity:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: decrementQuantity,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('$quantity', style: TextStyle(fontSize: 18)),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: incrementQuantity,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Add to cart
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: addToCart,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text(
                        "ADD TO CART",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Description
                  Text("Product Description",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}