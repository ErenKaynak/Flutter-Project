import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../pages/theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BannerManagementPage extends StatefulWidget {
  const BannerManagementPage({super.key});

  @override
  State<BannerManagementPage> createState() => _BannerManagementPageState();
}

class _BannerManagementPageState extends State<BannerManagementPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  List<Map<String, dynamic>> banners = [];
  bool _isLoading = true;
  XFile? _webImageFile;

  // Available theme colors for banners
  final List<String> themeColors = ['default', 'red', 'purple', 'blue', 'green', 'pink'];

  Color _getThemeColor(String colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'pink':
        return Colors.pink;
      default:
        return Colors.grey; // Default color when no specific theme is selected
    }
  }
  
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('banners')
          .orderBy('order', descending: false)
          .get();

      setState(() {
        banners = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'imageUrl': data['imageUrl'] ?? '',
            'title': data['title'] ?? '',
            'description': data['description'] ?? '',
            'order': data['order'] ?? 0,
            'isActive': data['isActive'] ?? true,
            'themeColor': data['themeColor'] ?? 'default',
            'createdAt': data['createdAt'],
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading banners: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading banners: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addBanner() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image == null) return;

    if (kIsWeb) {
      setState(() {
        _webImageFile = image;
      });
      _showBannerDialog(webImageFile: image);
    } else {
      _showBannerDialog(imageFile: File(image.path));
    }
  }

  void _showBannerDialog({File? imageFile, XFile? webImageFile, Map<String, dynamic>? banner}) {
    final TextEditingController titleController = TextEditingController(text: banner?['title'] ?? '');
    final TextEditingController descriptionController = TextEditingController(text: banner?['description'] ?? '');
    final TextEditingController orderController = TextEditingController(text: banner?['order']?.toString() ?? '0');
    String selectedTheme = banner?['themeColor'] ?? 'default';
    bool isActive = banner?['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(banner == null ? 'Add Banner' : 'Edit Banner'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageFile != null || webImageFile != null)
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb && webImageFile != null
                          ? FutureBuilder<Uint8List>(
                              future: webImageFile.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return Center(child: CircularProgressIndicator());
                              },
                            )
                          : Image.file(imageFile!, fit: BoxFit.cover),
                    ),
                  )
                else if (banner != null && banner['imageUrl'].isNotEmpty)
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        banner['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: orderController,
                  decoration: InputDecoration(
                    labelText: 'Display Order',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTheme,
                  decoration: InputDecoration(
                    labelText: 'Theme Color',
                    border: OutlineInputBorder(),
                  ),
                  items: themeColors.map((String color) {
                    final displayName = color == 'default' ? 'All Themes' 
                        : color[0].toUpperCase() + color.substring(1);
                    return DropdownMenuItem<String>(
                      value: color,
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: color == 'default' ? null : _getThemeColor(color),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTheme = value ?? 'default';
                    });
                  },
                ),
                SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Active'),
                  value: isActive,
                  onChanged: (value) {
                    setState(() {
                      isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (banner == null && imageFile == null && webImageFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select an image')),
                  );
                  return;
                }

                Navigator.pop(context);
                await _saveBanner(
                  imageFile: imageFile,
                  webImageFile: webImageFile,
                  title: titleController.text,
                  description: descriptionController.text,
                  order: int.tryParse(orderController.text) ?? 0,
                  isActive: isActive,
                  themeColor: selectedTheme,
                  bannerId: banner?['id'],
                  existingImageUrl: banner?['imageUrl'],
                );
              },
              child: Text(banner == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBanner({
    File? imageFile,
    XFile? webImageFile,
    required String title,
    required String description,
    required int order,
    required bool isActive,
    required String themeColor,
    String? bannerId,
    String? existingImageUrl,
  }) async {
    setState(() {
      _isUploading = true;
    });

    try {
      String imageUrl = existingImageUrl ?? '';

      // Upload new image if provided
      if (imageFile != null || webImageFile != null) {
        final String fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('banners')
            .child(fileName);

        UploadTask uploadTask;
        if (kIsWeb && webImageFile != null) {
          // Handle web platform
          final bytes = await webImageFile.readAsBytes();
          uploadTask = storageRef.putData(bytes);
        } else if (imageFile != null) {
          // Handle mobile platforms
          uploadTask = storageRef.putFile(imageFile);
        } else {
          throw Exception('No image file provided');
        }

        final TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      final Map<String, dynamic> bannerData = {
        'imageUrl': imageUrl,
        'title': title,
        'description': description,
        'order': order,
        'isActive': isActive,
        'themeColor': themeColor,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (bannerId == null) {
        // Add new banner
        bannerData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('banners').add(bannerData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.bannerAddedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing banner
        await FirebaseFirestore.instance
            .collection('banners')
            .doc(bannerId)
            .update(bannerData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.bannerUpdatedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      await _loadBanners();
    } catch (e) {
      print('Error saving banner: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving banner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
        _webImageFile = null;
      });
    }
  }

  Future<void> _deleteBanner(String bannerId, String imageUrl) async {
    final l10n = AppLocalizations.of(context)!;
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.deleteBannerConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete from Firestore
      await FirebaseFirestore.instance.collection('banners').doc(bannerId).delete();

      // Delete image from Storage
      if (imageUrl.isNotEmpty) {
        try {
          final Reference imageRef = FirebaseStorage.instance.refFromURL(imageUrl);
          await imageRef.delete();
        } catch (e) {
          print('Error deleting image from storage: $e');
        }
      }

      await _loadBanners();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.bannerDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting banner: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting banner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reorderBanners(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    setState(() {
      final banner = banners.removeAt(oldIndex);
      banners.insert(newIndex, banner);
      
      // Update orders
      for (int i = 0; i < banners.length; i++) {
        banners[i]['order'] = i;
      }
    });

    // Update orders in Firestore
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final banner in banners) {
        final docRef = FirebaseFirestore.instance
            .collection('banners')
            .doc(banner['id']);
        batch.update(docRef, {'order': banner['order']});
      }
      await batch.commit();
    } catch (e) {
      print('Error updating banner orders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating banner orders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Reload original order
      await _loadBanners();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(l10n.bannerManagement),
        backgroundColor: themeColor,
        elevation: isDark ? 0 : 2,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isUploading)
                  LinearProgressIndicator(
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                Expanded(
                  child: banners.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                l10n.noBannersFound,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                l10n.addFirstBanner,
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: banners.length,
                          onReorder: _reorderBanners,
                          itemBuilder: (context, index) {
                            final banner = banners[index];
                            final themeColor = _getThemeColor(banner['themeColor'] ?? 'default');
                            
                            return Card(
                              key: ValueKey(banner['id']),
                              margin: EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (banner['imageUrl'].isNotEmpty)
                                    Container(
                                      height: 200,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: themeColor.withOpacity(0.5),
                                            width: 4,
                                          ),
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            banner['imageUrl'],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: Icon(Icons.error),
                                              );
                                            },
                                          ),
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.drag_handle,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Drag to reorder',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ListTile(
                                    title: Text(banner['title'] ?? ''),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (banner['description']?.isNotEmpty ?? false)
                                          Padding(
                                            padding: EdgeInsets.only(top: 4),
                                            child: Text(banner['description']),
                                          ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Wrap(
                                            spacing: 8,
                                            children: [
                                              Chip(
                                                label: Text(
                                                  'Theme: ${_capitalizeFirst(banner['themeColor'] ?? 'default')}',
                                                  style: TextStyle(
                                                    color: banner['themeColor'] == 'default' 
                                                      ? null 
                                                      : Colors.white,
                                                  ),
                                                ),
                                                backgroundColor: banner['themeColor'] == 'default'
                                                  ? Colors.grey[200]
                                                  : themeColor,
                                              ),
                                              Chip(
                                                label: Text('Order: ${banner['order']}'),
                                                backgroundColor: Colors.grey[200],
                                              ),
                                              Chip(
                                                label: Text(
                                                  banner['isActive'] ? 'Active' : 'Inactive',
                                                  style: TextStyle(
                                                    color: banner['isActive'] 
                                                      ? Colors.white 
                                                      : null,
                                                  ),
                                                ),
                                                backgroundColor: banner['isActive']
                                                  ? Colors.green
                                                  : Colors.grey[200],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () => _showBannerDialog(banner: banner),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () => _deleteBanner(
                                            banner['id'],
                                            banner['imageUrl'],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBanner,
        backgroundColor: themeColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
