import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math' as Math;

class AdminProducts extends StatefulWidget {
  const AdminProducts({super.key});

  @override
  State<AdminProducts> createState() => _AdminProductsState();
}

class _AdminProductsState extends State<AdminProducts> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController imagePathController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  
  // Search functionality
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  
  // For additional images - added more controllers for flexibility
  final List<TextEditingController> additionalImagesControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),  // Added one more image slot
  ];
  
  // Category selection
  String selectedCategory = "CPU's"; // Default category
  final List<String> categories = [
    "CPU's", 
    "GPU's", 
    "RAM's", 
    "Storage", 
    "Motherboards",
    "Cases",
    "PSUs"
  ];

  final CollectionReference products =
      FirebaseFirestore.instance.collection('products');

  @override
  void initState() {
    super.initState();
    // Set up search listener
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    nameController.dispose();
    priceController.dispose();
    imagePathController.dispose();
    descriptionController.dispose();
    stockController.dispose();
    for (var controller in additionalImagesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text.trim().toLowerCase();
    });
  }

  void showProductDialog({DocumentSnapshot? doc}) {
    final isEditing = doc != null;
    
    // Reset all fields
    nameController.clear();
    priceController.clear();
    imagePathController.clear();
    descriptionController.clear();
    stockController.text = '0';
    selectedCategory = "CPU's";
    additionalImagesControllers.forEach((controller) => controller.clear());
    
    if (isEditing) {
      // Populate fields with existing product data
      nameController.text = doc['name'] ?? '';
      priceController.text = doc['price']?.toString() ?? '';
      imagePathController.text = doc['imagePath'] ?? '';
      descriptionController.text = doc['description'] ?? '';
      stockController.text = (doc['stock'] ?? 0).toString();
      
      // Handle category selection
      String docCategory = doc['category'] ?? 'CPU\'s';
      if (categories.contains(docCategory)) {
        selectedCategory = docCategory;
      }
      
      // Handle additional images array
      List<dynamic> images = doc['images'] ?? [];
      for (int i = 0; i < Math.min(images.length, additionalImagesControllers.length); i++) {
        additionalImagesControllers[i].text = images[i].toString();
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isEditing ? 'Edit Product' : 'Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price (TRY)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stock Quantity'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: imagePathController,
                  decoration: const InputDecoration(labelText: 'Main Image URL'),
                ),
                const SizedBox(height: 10),
                const Text("Additional Images", style: TextStyle(fontWeight: FontWeight.bold)),
                ...additionalImagesControllers.asMap().entries.map((entry) {
                  int index = entry.key;
                  TextEditingController controller = entry.value;
                  return TextField(
                    controller: controller,
                    decoration: InputDecoration(labelText: 'Image URL ${index + 1}'),
                  );
                }).toList(),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () async {
                final name = nameController.text.trim();
                final priceText = priceController.text.trim();
                final imagePath = imagePathController.text.trim();
                final description = descriptionController.text.trim();
                final stockText = stockController.text.trim();
                
                // Validation
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a product name')),
                  );
                  return;
                }
                
                // Parse price (allow both integer and decimal values)
                double? price = double.tryParse(priceText);
                if (priceText.isEmpty || price == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid price')),
                  );
                  return;
                }
                
                // Prepare additional images array
                List<String> additionalImages = [];
                for (var controller in additionalImagesControllers) {
                  String url = controller.text.trim();
                  if (url.isNotEmpty) {
                    additionalImages.add(url);
                  }
                }

                // Prepare the product data object
                final Map<String, dynamic> productData = {
                  'name': name,
                  'price': price,  // Store as numeric value
                  'category': selectedCategory,
                  'stock': int.tryParse(stockText) ?? 0,
                  'description': description,
                  'imagePath': imagePath,
                  'images': additionalImages,
                  'updatedAt': FieldValue.serverTimestamp(), // Track when the product was last updated
                };

                try {
                  if (isEditing) {
                    // Update existing product
                    await products.doc(doc!.id).update(productData);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product updated successfully')),
                      );
                    }
                  } else {
                    // Add new product
                    productData['createdAt'] = FieldValue.serverTimestamp(); // Add creation timestamp
                    await products.add(productData);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product added successfully')),
                      );
                    }
                  }
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Add', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void deleteProduct(String id) async {
    // Confirmation dialog before deletion
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await products.doc(id).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting product: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        title: const Text('Manage Products', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                // Force refresh the stream
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showProductDialog(),
        backgroundColor: Colors.red.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade700, width: 2),
                ),
              ),
            ),
          ),
          // Product List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: products.orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final productDocs = snapshot.data!.docs;
                
                if (productDocs.isEmpty) {
                  return const Center(child: Text('No products found. Add some!'));
                }

                // Filter products based on search query
                var filteredProducts = productDocs;
                if (searchQuery.isNotEmpty) {
                  filteredProducts = productDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final description = (data['description'] ?? '').toString().toLowerCase();
                    final category = (data['category'] ?? '').toString().toLowerCase();
                    
                    return name.contains(searchQuery) || 
                           description.contains(searchQuery) ||
                           category.contains(searchQuery);
                  }).toList();
                }
                
                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No products matching "${searchController.text}"'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final doc = filteredProducts[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final name = data['name'] ?? 'Unknown Product';
                    final price = data['price']?.toString() ?? '0';
                    final imagePath = data['imagePath'] ?? '';
                    final description = data['description'] ?? '';
                    final category = data['category'] ?? 'Uncategorized';
                    final stock = data['stock'] ?? 0;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ExpansionTile(
                        leading: imagePath.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imagePath,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.image_not_supported, color: Colors.red.shade300, size: 50);
                                  },
                                ),
                              )
                            : Icon(Icons.inventory_2, color: Colors.red.shade700, size: 40),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '₺$price • Category: $category • Stock: $stock',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue.shade700),
                              onPressed: () => showProductDialog(doc: doc),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteProduct(doc.id),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (description.isNotEmpty) ...[
                                  const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(description),
                                  const SizedBox(height: 8),
                                ],
                                
                                // Display additional images if available
                                if ((data['images'] as List<dynamic>?)?.isNotEmpty ?? false) ...[
                                  const Text('Additional Images:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: (data['images'] as List<dynamic>).length,
                                      itemBuilder: (context, imgIndex) {
                                        final imgUrl = (data['images'] as List<dynamic>)[imgIndex];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8.0),
                                            child: Image.network(
                                              imgUrl,
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  height: 100,
                                                  width: 100,
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(Icons.broken_image),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}