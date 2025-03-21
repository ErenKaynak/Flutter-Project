import 'package:flutter/material.dart';

class ProductDetailPage extends StatefulWidget {
  final String name;
  final String price;
  final String imagePath;
  final String category;
  final String description;

  const ProductDetailPage({
    Key? key,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.category,
    this.description = "No description available for this product.",
  }) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  int selectedImageIndex = 0;

  // In a real app, you'd fetch these from a database
  List<String> getProductImages() {
    // This is a mock function. In a real app, you'd fetch multiple images.
    // For now, we'll just duplicate the main image to simulate multiple views
    return [
      widget.imagePath,
      widget.imagePath, // Simulating another angle
      widget.imagePath, // Simulating another angle
    ];
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

  void addToCart() {
    // Here you'd implement your cart logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.name} x$quantity added to cart'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> images = getProductImages();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to cart page
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main product image
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: Image.asset(
                images[selectedImageIndex],
                fit: BoxFit.contain,
              ),
            ),
            
            // Image selector row
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedImageIndex = index;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.all(8),
                      width: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedImageIndex == index 
                              ? Colors.red 
                              : Colors.grey,
                          width: 2,
                        ),
                        color: Colors.grey[200],
                      ),
                      child: Image.asset(
                        images[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Product details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Category: ${widget.category}",
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        widget.price,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Quantity selector
                  Row(
                    children: [
                      Text(
                        "Quantity:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                              child: Text(
                                quantity.toString(),
                                style: TextStyle(fontSize: 18),
                              ),
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
                  
                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text(
                        "ADD TO CART",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Product description
                  Text(
                    "Product Description",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  
                  // Additional specifications could go here
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
