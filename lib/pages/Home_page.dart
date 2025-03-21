import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Ensure Firebase is initialized
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

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedCategory = "All"; // Track the selected category

  // Updated products list with category information
  final List<Map<String, String>> products = [
    {
      "image": "lib/assets/Images/rtx-4090.png",
      "name": "RTX 4090",
      "price": "\$1599.99",
      "category": "GPU's", // Added category
    },
    {
      "image": "lib/assets/Images/rtx-4080.png",
      "name": "RTX 4080",
      "price": "\$1199.99",
      "category": "GPU's",
    },
    {
      "image": "lib/assets/Images/rtx-4070.png",
      "name": "RTX 4070",
      "price": "\$699.99",
      "category": "GPU's",
    },
    {
      "image": "lib/assets/Images/rtx-4060.png",
      "name": "RTX 4060",
      "price": "\$499.99",
      "category": "GPU's",
    },
    {
      "image": "lib/assets/Images/asus-tuf-radeon-rx-7900-xtx.png",
      "name": "RADEON RX 7900 XTX",
      "price": "\$1099.99",
      "category": "GPU's",
    },
    {
      "image": "lib/assets/Images/radeon-rx-9070-xt.png",
      "name": "RADEON RX 9070 XT",
      "price": "\$1399.99",
      "category": "GPU's",
    },
    // Add some sample products for other categories
    {
      "image":
          "lib/assets/Images/ROG-Strix-Z790.png", // You'll need to add these images
      "name": "ASUS ROG Z790",
      "price": "\$499.99",
      "category": "Motherboards",
    },
    {
      "image": "lib/assets/Images/msi-b650-gaming-plus.png",
      "name": "MSI MPG B650",
      "price": "\$329.99",
      "category": "Motherboards",
    },
    {
      "image": "lib/assets/Images/Intel i9-14900K.png",
      "name": "Intel i9-14900K",
      "price": "\$599.99",
      "category": "CPU's",
    },
    {
      "image": "lib/assets/Images/AMD Ryzen 9 7950X.png",
      "name": "AMD Ryzen 9 7950X",
      "price": "\$549.99",
      "category": "CPU's",
    },
    {
      "image": "lib/assets/Images/corshair-vengence.png",
      "name": "Corsair Vengeance 32GB",
      "price": "\$149.99",
      "category": "RAM's",
    },
    {
      "image": "lib/assets/Images/trident-z5.png",
      "name": "G.Skill Trident Z5 ROYAL 2x24GB",
      "price": "\$299.99",
      "category": "RAM's",
    },
  ];

  // Get filtered products based on selected category
  List<Map<String, String>> get filteredProducts {
    if (_selectedCategory == "All") {
      return products;
    } else {
      return products
          .where((product) => product["category"] == _selectedCategory)
          .toList();
    }
  }

  // Method to handle category selection
  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Container(
            height: 40, // Set a fixed height for proper alignment
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.search, size: 25),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                ), // Adjust vertical alignment
                alignLabelWithHint: true,
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CategoryButton(icon: Icons.favorite, label: "Favorites"),
                    CategoryButton(icon: Icons.history, label: "History"),
                    CategoryButton(icon: Icons.person, label: "Following"),
                  ],
                ),
              ),
              // Banner Section
              Container(
                margin: EdgeInsets.all(10),
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300], // Placeholder for the banner
                ),
                child: Center(
                  child: Text('Banner Title'), //Image.asset(''),
                ),
              ),
              SizedBox(height: 10),
              // Categories Section
              Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Categories",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Clear filter button
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = "All";
                        });
                      },
                      child: Text(
                        "Show All",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Make CategoryCircle interactive
                    CategoryCircle(
                      label: "GPU's",
                      imagePath: 'lib/assets/Images/gpu-icon.png',
                      isSelected: _selectedCategory == "GPU's",
                      onTap: () => _selectCategory("GPU's"),
                    ),
                    SizedBox(width: 10),
                    CategoryCircle(
                      label: "Motherboards",
                      imagePath: 'lib/assets/Images/motherboard-icon.png',
                      isSelected: _selectedCategory == "Motherboards",
                      onTap: () => _selectCategory("Motherboards"),
                    ),
                    SizedBox(width: 10),
                    CategoryCircle(
                      label: "CPU's",
                      imagePath: 'lib/assets/Images/cpu-icon.png',
                      isSelected: _selectedCategory == "CPU's",
                      onTap: () => _selectCategory("CPU's"),
                    ),
                    SizedBox(width: 10),
                    CategoryCircle(
                      label: "RAM's",
                      imagePath: 'lib/assets/Images/ram-icon.png',
                      isSelected: _selectedCategory == "RAM's",
                      onTap: () => _selectCategory("RAM's"),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory == "All"
                          ? "Best Deals"
                          : _selectedCategory,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Show product count
                    Text(
                      "${filteredProducts.length} products",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Use filteredProducts instead of products
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount:
                    filteredProducts
                        .length, // Now it shows only filtered products
                itemBuilder: (context, index) {
                  return ProductCard(
                    imagePath: filteredProducts[index]["image"]!,
                    name: filteredProducts[index]["name"]!,
                    price: filteredProducts[index]["price"]!,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;

  CategoryButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {}, // Ensures the entire button is clickable
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white, // Button background color
          border: Border.all(color: Colors.black, width: 0.8), // Outline
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 24), SizedBox(width: 8), Text(label)],
        ),
      ),
    );
  }
}

class CategoryCircle extends StatelessWidget {
  final String label;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  CategoryCircle({
    required this.label,
    required this.imagePath,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor:
                isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[300],
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    isSelected
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.fill,
                width: 50,
                height: 50,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String imagePath;
  final String name;
  final String price;

  ProductCard({
    required this.imagePath,
    required this.name,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[300],
              child: Center(child: Image.asset(imagePath)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(price, style: TextStyle(color: Colors.green)),
              ],
            ),
          ),
          OverflowBar(
            alignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: () {}, child: Text("Add to Cart")),
            ],
          ),
        ],
      ),
    );
  }
}
