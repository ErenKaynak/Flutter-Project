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

class HomePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Map<String, String>> products = [
    {
      "image": "lib/assets/Images/rtx-4090.png",
      "name": "RTX 4090",
      "price": "\$1599.99",
    },
    {
      "image": "lib/assets/Images/rtx-4080.png",
      "name": "RTX 4080",
      "price": "\$1199.99",
    },
    {
      "image": "lib/assets/Images/rtx-4070.png",
      "name": "RTX 4070",
      "price": "\$699.99",
    },
    {
      "image": "lib/assets/Images/rtx-4060.png",
      "name": "RTX 4060",
      "price": "\$499.99",
    },
  ];

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
                  child: Image.asset('lib/assets/images/bannertest.png'),
                ),
              ),
              SizedBox(height: 10),
              // Categories Section
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  "Categories",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Center( 
                
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CategoryCircle(label: "Graphic\nCards",imagePath: 'lib/assets/Images/gpu-icon.png',),
                    SizedBox(width: 10),
                    CategoryCircle(label: "Motherboards",imagePath: 'lib/assets/Images/motherboard-icon.png'),
                    SizedBox(width: 10),
                    CategoryCircle(label: "CPU's",imagePath: 'lib/assets/Images/cpu-icon.png'),
                    SizedBox(width: 10),
                    CategoryCircle(label: "RAM's",imagePath: 'lib/assets/Images/ram-icon.png'),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  "Best Deals",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: products.length, // Now it dynamically adjusts
                itemBuilder: (context, index) {
                  return ProductCard(
                    imagePath: products[index]["image"]!,
                    name: products[index]["name"]!,
                    price: products[index]["price"]!,
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

  CategoryCircle({required this.label, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 35, // Keep the circle radius the same
          backgroundColor: Colors.grey[300], // Placeholder for image
          child:Image.asset(
              imagePath,
              fit: BoxFit.fill,
              width: 50, // Adjust the width to shrink the image
              height: 50, // Adjust the height to shrink the image
            ),
        ),
        Text(label),
      ],
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


