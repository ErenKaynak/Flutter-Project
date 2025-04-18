import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CategoryManagementPage extends StatefulWidget {
  @override
  _CategoryManagementPageState createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .get();
      
      setState(() {
        categories = snapshot.docs.map((doc) {
          final data = doc.data();
          print('Category data: ${doc.id} - ${data.toString()}'); // Debug print
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unnamed Category',
            'iconPath': data['iconPath'] ?? '',
          };
        }).toList();
        _isLoading = false;
      });
      
      print('Loaded categories: ${categories.length}'); // Debug print
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        categories = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _addCategory() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and select an icon')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('category_icons/${DateTime.now().millisecondsSinceEpoch}.png');
      
      await storageRef.putFile(_imageFile!);
      final iconUrl = await storageRef.getDownloadURL();

      // Add category to Firestore
      await FirebaseFirestore.instance.collection('categories').add({
        'name': _nameController.text,
        'iconPath': iconUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Reset form
      _nameController.clear();
      setState(() {
        _imageFile = null;
      });

      // Reload categories
      await _loadCategories();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category added successfully')),
      );
    } catch (e) {
      print('Error adding category: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding category: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteCategory(String categoryId) async {
    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .delete();
      
      await _loadCategories();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category deleted successfully')),
      );
    } catch (e) {
      print('Error deleting category: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting category')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Category Management'),
        backgroundColor: isDark ? Colors.black : Colors.red.shade700,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Category',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Category Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a category name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  icon: Icon(Icons.image),
                                  label: Text('Select Icon'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                ),
                                SizedBox(width: 16),
                                if (_imageFile != null)
                                  Expanded(
                                    child: Text(
                                      'Icon selected',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _addCategory,
                              child: Text('Add Category'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                minimumSize: Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Existing Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Card(
                        child: ListTile(
                          leading: category['iconPath']?.isNotEmpty == true
                              ? Image.network(
                                  category['iconPath']!,
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading image: $error'); // Debug print
                                    return Icon(Icons.error);
                                  },
                                )
                              : Icon(Icons.category),
                          title: Text(category['name'] ?? 'Unnamed Category'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Delete Category'),
                                content: Text(
                                  'Are you sure you want to delete this category?'
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteCategory(category['id']);
                                    },
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}