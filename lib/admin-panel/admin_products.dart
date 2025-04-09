import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  final CollectionReference products = FirebaseFirestore.instance.collection('products');

  void showProductDialog({DocumentSnapshot? doc}) {
    final isEditing = doc != null;
    if (isEditing) {
      nameController.text = doc['name'];
      priceController.text = doc['price'].toString();
      imagePathController.text = doc['imagePath'] ?? '';
      descriptionController.text = doc['description'] ?? '';
    } else {
      nameController.clear();
      priceController.clear();
      imagePathController.clear();
      descriptionController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: imagePathController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
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
              final price = double.tryParse(priceController.text.trim());
              final imagePath = imagePathController.text.trim();
              final description = descriptionController.text.trim();

              if (name.isEmpty || price == null) return;

              final productData = {
                'name': name,
                'price': price,
                'imagePath': imagePath,
                'description': description,
              };

              if (isEditing) {
                await products.doc(doc!.id).update(productData);
              } else {
                await products.add(productData);
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void deleteProduct(String id) async {
    await products.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        title: const Text('Manage Products', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showProductDialog(),
        backgroundColor: Colors.red.shade700,
        child: const Icon(Icons.add,color: Colors.white),
        ),
      body: StreamBuilder<QuerySnapshot>(
        stream: products.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final productDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: productDocs.length,
            itemBuilder: (context, index) {
              final doc = productDocs[index];
              final name = doc['name'];
              final price = doc['price'];
              final imagePath = doc['imagePath'] ?? '';
              final description = doc['description'] ?? '';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: imagePath.isNotEmpty
                      ? CircleAvatar(backgroundImage: NetworkImage(imagePath))
                      : Icon(Icons.inventory_2, color: Colors.red.shade700),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('€$price'),
                      if (description.isNotEmpty)
                        Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.red.shade700),
                        onPressed: () => showProductDialog(doc: doc),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red.shade700),
                        onPressed: () => deleteProduct(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}