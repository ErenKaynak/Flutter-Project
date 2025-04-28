import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:engineering_project/assets/components/theme_data.dart';

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

  void _debugPrintCategories() {
    print('Current categories length: ${categories.length}');
    for (var category in categories) {
      print(
        'Category: ${category['name']} - ID: ${category['id']} - Order: ${category['order']}',
      );
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order') // Add ordering
          .get();

      final loadedCategories = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed Category',
          'iconPath': data['iconPath'] ?? '',
          'order': data['order'] ?? 999999,
        };
      }).toList();
=======
      final snapshot =
          await FirebaseFirestore.instance.collection('categories').get();

      print('Firestore snapshot size: ${snapshot.docs.length}');

=======
      final snapshot =
          await FirebaseFirestore.instance.collection('categories').get();

      print('Firestore snapshot size: ${snapshot.docs.length}');

>>>>>>> Stashed changes
      final loadedCategories =
          snapshot.docs.map((doc) {
            final data = doc.data();
            print('Loading category: ${doc.id} - ${data.toString()}');
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unnamed Category',
              'iconPath': data['iconPath'] ?? '',
              'order': data['order'] ?? 999999,
            };
          }).toList();
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes

      setState(() {
        categories = loadedCategories;
        _isLoading = false;
      });

<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
      _debugPrintCategories();
>>>>>>> Stashed changes
=======
      _debugPrintCategories();
>>>>>>> Stashed changes
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
      final storageRef = FirebaseStorage.instance.ref().child(
        'category_icons/${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await storageRef.putFile(_imageFile!);
      final iconUrl = await storageRef.getDownloadURL();

      final nextOrder =
          categories.isEmpty
              ? 0
              : (categories.map((c) => c['order'] as int).reduce(max) + 1);

      await FirebaseFirestore.instance.collection('categories').add({
        'name': _nameController.text,
        'iconPath': iconUrl,
        'order': nextOrder,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _nameController.clear();
      setState(() {
        _imageFile = null;
      });

      await _loadCategories();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Category added successfully')));
    } catch (e) {
      print('Error adding category: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding category: $e')));
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Category deleted successfully')));
    } catch (e) {
      print('Error deleting category: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting category')));
    }
  }

  Future<void> _updateCategoryOrder() async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        final docRef = FirebaseFirestore.instance
            .collection('categories')
            .doc(category['id']);

        batch.update(docRef, {'order': i});
        
        // Update local state
        categories[i]['order'] = i;
      }

      await batch.commit();
      
      // Refresh the categories to ensure order is updated
      await _loadCategories();
    } catch (e) {
      print('Error updating category order: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating category order')));
    }
  }

  Future<void> _editCategory(Map<String, dynamic> category) async {
  final TextEditingController nameController = TextEditingController(text: category['name']);
  File? newImageFile;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Edit Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Category Name'),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            newImageFile = File(image.path);
                          });
                        }
                      },
                      icon: Icon(Icons.image),
                      label: Text('Change Icon'),
                    ),
                  ),
                ],
              ),
              if (newImageFile != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'New icon selected',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateCategory(
                category['id'],
                nameController.text,
                newImageFile,
              );
            },
            child: Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _updateCategory(String categoryId, String newName, File? newImageFile) async {
  try {
    final updates = <String, dynamic>{
      'name': newName,
    };

    if (newImageFile != null) {
      // Upload new image
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('category_icons/${DateTime.now().millisecondsSinceEpoch}.png');
      
      await storageRef.putFile(newImageFile);
      final iconUrl = await storageRef.getDownloadURL();
      
      updates['iconPath'] = iconUrl;
    }

    await FirebaseFirestore.instance
        .collection('categories')
        .doc(categoryId)
        .update(updates);

    await _loadCategories();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Category updated successfully')),
    );
  } catch (e) {
    print('Error updating category: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating category')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isBlackMode = themeNotifier.isBlackMode;
    final isDark =
        Theme.of(context).brightness == Brightness.dark && !isBlackMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('Category Management'),
        backgroundColor:
            isBlackMode
                ? Colors.black
                : isDark
                ? Colors.black
                : Colors.red.shade700,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color:
                          isBlackMode
                              ? Colors.black
                              : null, // Black mode'da kart siyah
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
                                  color: isBlackMode ? Colors.white : null,
                                ),
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Category Name',
                                  border: OutlineInputBorder(),
                                  labelStyle: TextStyle(
                                    color: isBlackMode ? Colors.white : null,
                                  ),
                                ),
                                style: TextStyle(
                                  color: isBlackMode ? Colors.white : null,
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
                                      backgroundColor:
                                          isBlackMode
                                              ? Colors.grey.shade500
                                              : Colors.red.shade700,
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
                                  backgroundColor:
                                      isBlackMode
                                          ? Colors.grey.shade500
                                          : Colors.red.shade700,
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
                      'Existing Categories (${categories.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isBlackMode ? Colors.white : null,
                      ),
                    ),
                    SizedBox(height: 16),
                    categories.isEmpty
                        ? Center(
                          child: Text(
                            'No categories found. Add your first category above.',
                            style: TextStyle(
                              color:
                                  isBlackMode
                                      ? Colors.grey.shade400
                                      : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                        : ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: categories.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              final item = categories.removeAt(oldIndex);
                              categories.insert(newIndex, item);
                              _updateCategoryOrder();
                            });
                          },
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            print(
                              'Building category at index $index: ${category['name']}',
                            );
                            return Card(
                              key: ValueKey(category['id']),
                              margin: EdgeInsets.symmetric(vertical: 4),
                              color:
                                  isBlackMode
                                      ? Colors.black
                                      : null, // Black mode'da kart siyah
                              child: ListTile(
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.drag_handle,
                                      color: isBlackMode ? Colors.white : null,
                                    ),
                                    SizedBox(width: 8),
                                    if (category['iconPath']?.isNotEmpty ==
                                        true)
                                      Image.network(
                                        category['iconPath']!,
                                        width: 40,
                                        height: 40,
<<<<<<< Updated upstream
<<<<<<< Updated upstream
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Error loading image: $error');
                                          return Icon(Icons.error);
=======
=======
>>>>>>> Stashed changes
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          print('Error loading image: $error');
                                          return Icon(
                                            Icons.error,
                                            color:
                                                isBlackMode
                                                    ? Colors.white
                                                    : null,
                                          );
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
                                        },
                                      )
                                    else
                                      Icon(
                                        Icons.category,
                                        color:
                                            isBlackMode ? Colors.white : null,
                                      ),
                                  ],
                                ),
<<<<<<< Updated upstream
<<<<<<< Updated upstream
                                title: Text(category['name'] ?? 'Unnamed Category'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editCategory(category),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Delete Category'),
                                          content: Text('Are you sure you want to delete this category?'),
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
                                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
=======
=======
>>>>>>> Stashed changes
                                title: Text(
                                  category['name'] ?? 'Unnamed Category',
                                  style: TextStyle(
                                    color: isBlackMode ? Colors.white : null,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed:
                                      () => showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              backgroundColor:
                                                  isBlackMode
                                                      ? Colors.black
                                                      : null,
                                              title: Text(
                                                'Delete Category',
                                                style: TextStyle(
                                                  color:
                                                      isBlackMode
                                                          ? Colors.white
                                                          : null,
                                                ),
                                              ),
                                              content: Text(
                                                'Are you sure you want to delete this category?',
                                                style: TextStyle(
                                                  color:
                                                      isBlackMode
                                                          ? Colors.white
                                                          : null,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color:
                                                          isBlackMode
                                                              ? Colors.white
                                                              : null,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _deleteCategory(
                                                      category['id'],
                                                    );
                                                  },
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                      ),
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
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
