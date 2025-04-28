import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math' as Math;
import 'package:provider/provider.dart';
import 'package:engineering_project/pages/theme_notifier.dart';

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
    TextEditingController(), // Added one more image slot
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
    "PSUs",
  ];

  String selectedFilterCategory =
      "All"; // Add this line with your other state variables

  final CollectionReference products = FirebaseFirestore.instance.collection(
    'products',
  );

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
      for (
        int i = 0;
        i < Math.min(images.length, additionalImagesControllers.length);
        i++
      ) {
        additionalImagesControllers[i].text = images[i].toString();
      }
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setStateDialog) {
              final themeNotifier = Provider.of<ThemeNotifier>(context);
              final isBlackMode = themeNotifier.isBlackMode;
              return AlertDialog(
                backgroundColor:
                    isBlackMode
                        ? Colors.black
                        : Theme.of(context).dialogBackgroundColor,
                title: Text(
                  isEditing ? 'Edit Product' : 'Add Product',
                  style: TextStyle(
                    color:
                        isBlackMode
                            ? Colors.white
                            : Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        style: TextStyle(
                          color:
                              isBlackMode
                                  ? Colors.white
                                  : Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Product Name',
                          labelStyle: TextStyle(
                            color:
                                isBlackMode
                                    ? Colors.grey.shade400
                                    : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  isBlackMode
                                      ? Colors.grey.shade800
                                      : Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                      ),
                      TextField(
                        controller: priceController,
                        style: TextStyle(
                          color:
                              isBlackMode
                                  ? Colors.white
                                  : Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Price (TRY)',
                          labelStyle: TextStyle(
                            color:
                                isBlackMode
                                    ? Colors.grey.shade400
                                    : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  isBlackMode
                                      ? Colors.grey.shade800
                                      : Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: TextStyle(
                            color:
                                isBlackMode
                                    ? Colors.grey.shade400
                                    : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  isBlackMode
                                      ? Colors.grey.shade800
                                      : Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        dropdownColor:
                            isBlackMode
                                ? Colors.black
                                : Theme.of(context).cardColor,
                        style: TextStyle(
                          color:
                              isBlackMode
                                  ? Colors.white
                                  : Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                        ),
                        items:
                            categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color:
                                        isBlackMode
                                            ? Colors.white
                                            : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                  ),
                                ),
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
                        style: TextStyle(
                          color:
                              isBlackMode
                                  ? Colors.white
                                  : Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Stock Quantity',
                          labelStyle: TextStyle(
                            color:
                                isBlackMode
                                    ? Colors.grey.shade400
                                    : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  isBlackMode
                                      ? Colors.grey.shade800
                                      : Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: imagePathController,
                        style: TextStyle(
                          color:
                              isBlackMode
                                  ? Colors.white
                                  : Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Main Image URL',
                          labelStyle: TextStyle(
                            color:
                                isBlackMode
                                    ? Colors.grey.shade400
                                    : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  isBlackMode
                                      ? Colors.grey.shade800
                                      : Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Additional Images",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isBlackMode
                                  ? Colors.white
                                  : Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                        ),
                      ),
                      ...additionalImagesControllers.asMap().entries.map((
                        entry,
                      ) {
                        int index = entry.key;
                        TextEditingController controller = entry.value;
                        return TextField(
                          controller: controller,
                          style: TextStyle(
                            color:
                                isBlackMode
                                    ? Colors.white
                                    : Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Image URL ${index + 1}',
                            labelStyle: TextStyle(
                              color:
                                  isBlackMode
                                      ? Colors.grey.shade400
                                      : Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color:
                                    isBlackMode
                                        ? Colors.grey.shade800
                                        : Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descriptionController,
                        style: TextStyle(
                          color:
                              isBlackMode
                                  ? Colors.white
                                  : Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(
                            color:
                                isBlackMode
                                    ? Colors.grey.shade400
                                    : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  isBlackMode
                                      ? Colors.grey.shade800
                                      : Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isBlackMode ? Colors.grey.shade500 : Colors.red,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isBlackMode
                              ? Colors.grey.shade500
                              : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final priceText = priceController.text.trim();
                      final imagePath = imagePathController.text.trim();
                      final description = descriptionController.text.trim();
                      final stockText = stockController.text.trim();

                      // Validation
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a product name'),
                          ),
                        );
                        return;
                      }

                      // Parse price (allow both integer and decimal values)
                      double? price = double.tryParse(priceText);
                      if (priceText.isEmpty || price == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid price'),
                          ),
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
                        'price': price, // Store as numeric value
                        'category': selectedCategory,
                        'stock': int.tryParse(stockText) ?? 0,
                        'description': description,
                        'imagePath': imagePath,
                        'images': additionalImages,
                        'updatedAt':
                            FieldValue.serverTimestamp(), // Track when the product was last updated
                      };

                      try {
                        if (isEditing) {
                          // Update existing product
                          await products.doc(doc!.id).update(productData);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Product updated successfully'),
                              ),
                            );
                          }
                        } else {
                          // Add new product
                          productData['createdAt'] =
                              FieldValue.serverTimestamp(); // Add creation timestamp
                          await products.add(productData);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Product added successfully'),
                              ),
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
                    child: Text(
                      isEditing ? 'Update' : 'Add',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  void deleteProduct(String id) async {
    // Confirmation dialog before deletion
    showDialog(
      context: context,
      builder: (context) {
        final themeNotifier = Provider.of<ThemeNotifier>(context);
        final isBlackMode = themeNotifier.isBlackMode;
        return AlertDialog(
          backgroundColor:
              isBlackMode
                  ? Colors.black
                  : Theme.of(context).dialogBackgroundColor,
          title: Text(
            'Confirm Deletion',
            style: TextStyle(
              color:
                  isBlackMode
                      ? Colors.white
                      : Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this product? This action cannot be undone.',
            style: TextStyle(
              color:
                  isBlackMode
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                      isBlackMode
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await products.doc(id).delete();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product deleted successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error deleting product: ${e.toString()}',
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: isBlackMode ? Colors.grey.shade500 : Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isBlackMode = themeNotifier.isBlackMode;
    final isDark =
        Theme.of(context).brightness == Brightness.dark && !isBlackMode;

    return Scaffold(
      backgroundColor:
          isBlackMode
              ? Colors.black
              : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            isBlackMode
                ? Colors.black
                : isDark
                ? Colors.black
                : Theme.of(context).primaryColor,
        title: Text('Manage Products', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: isDark ? 0 : 2,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showProductDialog(),
        backgroundColor:
            isBlackMode ? Colors.grey.shade500 : Theme.of(context).primaryColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Header Section with Stats
          Container(
            padding: EdgeInsets.all(16.0),
            margin: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isBlackMode
                        ? [Colors.grey.shade500, Colors.black]
                        : isDark
                        ? [Colors.red.shade900, Colors.grey.shade900]
                        : [Colors.red.shade300, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow:
                  isDark || isBlackMode
                      ? []
                      : [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isBlackMode
                            ? Colors.grey.shade500
                            : isDark
                            ? Colors.red.shade900
                            : Colors.red.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.inventory_2, size: 30, color: Colors.white),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: products.snapshots(),
                    builder: (context, snapshot) {
                      final productCount = snapshot.data?.docs.length ?? 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Product Management",
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  isBlackMode
                                      ? Colors.grey.shade400
                                      : isDark
                                      ? Colors.grey[400]
                                      : Colors.black54,
                            ),
                          ),
                          Text(
                            "$productCount Products",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  isBlackMode
                                      ? Colors.white
                                      : isDark
                                      ? Colors.white
                                      : Colors.black87,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: searchController,
              style: TextStyle(
                color:
                    isBlackMode
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(
                  color:
                      isBlackMode
                          ? Colors.grey.shade400
                          : Theme.of(context).textTheme.bodyMedium?.color,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color:
                      isBlackMode
                          ? Colors.grey.shade400
                          : Theme.of(context).iconTheme.color,
                ),
                suffixIcon:
                    searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color:
                                isBlackMode
                                    ? Colors.grey.shade400
                                    : Theme.of(context).iconTheme.color,
                          ),
                          onPressed: () {
                            searchController.clear();
                            setState(() => searchQuery = '');
                          },
                        )
                        : null,
                filled: true,
                fillColor:
                    isBlackMode
                        ? Colors.grey.shade800
                        : (isDark ? Colors.grey.shade800 : Colors.grey.shade50),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        isBlackMode
                            ? Colors.grey.shade700
                            : (isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        isBlackMode
                            ? Colors.grey.shade500
                            : Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Category Filter
          Container(
            height: 60,
            margin: EdgeInsets.symmetric(vertical: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: ["All", ...categories].length, // Add "All" option
              itemBuilder: (context, index) {
                final category = index == 0 ? "All" : categories[index - 1];
                final isSelected = selectedFilterCategory == category;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(category),
                    onSelected: (selected) {
                      setState(() {
                        selectedFilterCategory = selected ? category : "All";
                      });
                    },
                    backgroundColor:
                        isBlackMode
                            ? Colors.grey.shade800
                            : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100),
                    selectedColor:
                        isBlackMode
                            ? Colors.grey.shade500.withOpacity(0.2)
                            : Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor:
                        isBlackMode
                            ? Colors.grey.shade500
                            : Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? (isBlackMode
                                  ? Colors.white
                                  : Theme.of(context).primaryColor)
                              : (isBlackMode
                                  ? Colors.grey.shade400
                                  : Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            isSelected
                                ? (isBlackMode
                                    ? Colors.grey.shade500
                                    : Theme.of(context).primaryColor)
                                : Colors.transparent,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Products List (existing StreamBuilder code)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: products.orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(
                        color:
                            isBlackMode
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color:
                          isBlackMode
                              ? Colors.grey.shade500
                              : Theme.of(context).primaryColor,
                    ),
                  );
                }

                final productDocs = snapshot.data!.docs;

                if (productDocs.isEmpty) {
                  return Center(
                    child: Text(
                      'No products found. Add some!',
                      style: TextStyle(
                        color:
                            isBlackMode
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  );
                }

                // Filter products based on search query
                var filteredProducts = productDocs;

                // Apply search filter
                if (searchQuery.isNotEmpty) {
                  filteredProducts =
                      productDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name =
                            (data['name'] ?? '').toString().toLowerCase();
                        final description =
                            (data['description'] ?? '')
                                .toString()
                                .toLowerCase();
                        final category =
                            (data['category'] ?? '').toString().toLowerCase();

                        return name.contains(searchQuery) ||
                            description.contains(searchQuery) ||
                            category.contains(searchQuery);
                      }).toList();
                }

                // Apply category filter
                if (selectedFilterCategory != "All") {
                  filteredProducts =
                      filteredProducts.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['category'] == selectedFilterCategory;
                      }).toList();
                }

                // Update the empty results message to include category
                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color:
                              isBlackMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'No products matching "${searchController.text}"'
                              : selectedFilterCategory != "All"
                              ? 'No products in category "$selectedFilterCategory"'
                              : 'No products found',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                isBlackMode
                                    ? Colors.white
                                    : Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                          ),
                        ),
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
                        side:
                            isBlackMode
                                ? BorderSide(color: Colors.grey.shade800)
                                : isDark
                                ? BorderSide(color: Colors.grey.shade800)
                                : BorderSide.none,
                      ),
                      color:
                          isBlackMode
                              ? Colors.black
                              : Theme.of(context).cardColor,
                      elevation: isDark ? 1 : 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ExpansionTile(
                        collapsedIconColor:
                            isBlackMode
                                ? Colors.grey.shade400
                                : Theme.of(context).iconTheme.color,
                        iconColor:
                            isBlackMode
                                ? Colors.grey.shade500
                                : Theme.of(context).primaryColor,
                        leading:
                            imagePath.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imagePath,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.image_not_supported,
                                        color:
                                            isBlackMode
                                                ? Colors.grey.shade400
                                                : (isDark
                                                    ? Colors.red.shade400
                                                    : Colors.red.shade300),
                                        size: 50,
                                      );
                                    },
                                  ),
                                )
                                : Icon(
                                  Icons.inventory_2,
                                  color:
                                      isBlackMode
                                          ? Colors.grey.shade500
                                          : Theme.of(context).primaryColor,
                                  size: 40,
                                ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isBlackMode
                                    ? Colors.white
                                    : Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.color,
                          ),
                        ),
                        subtitle: Text(
                          '₺$price • Category: $category • Stock: $stock',
                          style: TextStyle(
                            color:
                                isBlackMode
                                    ? Colors.grey.shade400
                                    : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: Colors.blue.shade700,
                              ),
                              onPressed: () => showProductDialog(doc: doc),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color:
                                    isBlackMode
                                        ? Colors.grey.shade500
                                        : Colors.red,
                              ),
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
                                  Text(
                                    'Description:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isBlackMode
                                              ? Colors.white
                                              : Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      color:
                                          isBlackMode
                                              ? Colors.grey.shade400
                                              : Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                // Display additional images if available
                                if ((data['images'] as List<dynamic>?)
                                        ?.isNotEmpty ??
                                    false) ...[
                                  Text(
                                    'Additional Images:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isBlackMode
                                              ? Colors.white
                                              : Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount:
                                          (data['images'] as List<dynamic>)
                                              .length,
                                      itemBuilder: (context, imgIndex) {
                                        final imgUrl =
                                            (data['images']
                                                as List<dynamic>)[imgIndex];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8.0,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                            child: Image.network(
                                              imgUrl,
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Container(
                                                  height: 100,
                                                  width: 100,
                                                  color:
                                                      isBlackMode
                                                          ? Colors.grey.shade800
                                                          : Colors
                                                              .grey
                                                              .shade200,
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color:
                                                        isBlackMode
                                                            ? Colors
                                                                .grey
                                                                .shade400
                                                            : Colors.grey,
                                                  ),
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
