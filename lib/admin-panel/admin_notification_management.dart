// Add lint ignore for file-long lines
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../pages/theme_notifier.dart';
import '../assets/components/notification_service.dart';

class AdminNotificationManagement extends StatefulWidget {
  const AdminNotificationManagement({Key? key}) : super(key: key);

  @override
  State<AdminNotificationManagement> createState() => _AdminNotificationManagementState();
}

class _AdminNotificationManagementState extends State<AdminNotificationManagement> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _discountCodeController = TextEditingController();
  bool _sendToAllUsers = true;
  List<String> _selectedUsers = [];
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String _selectedType = 'general';

  // Fix Text widget constructor linting issues
  Widget _buildTitle(String text, {bool isBold = false}) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontSize: isBold ? 16 : 14,
      ),
    );
  }

  // Fix the user selection widget
  Widget _buildUserSelection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildTitle('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[850] 
                : Colors.grey[100],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle('Select Users', isBold: true),
              const SizedBox(height: 8),
              ...snapshot.data!.docs.map((doc) {
                final userData = doc.data() as Map<String, dynamic>;
                final userId = doc.id;
                final userName = userData['displayName'] as String? ?? 'User $userId';
                
                return CheckboxListTile(
                  title: _buildTitle(userName),
                  value: _selectedUsers.contains(userId),
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        if (value) {
                          _selectedUsers.add(userId);
                        } else {
                          _selectedUsers.remove(userId);
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Fix the image picker widget
  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[850] 
              : Colors.grey[100],
        ),
        child: _imageFile != null
            ? _buildSelectedImage()
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildSelectedImage() {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _imageFile!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: _buildRemoveImageButton(),
        ),
      ],
    );
  }

  Widget _buildRemoveImageButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => setState(() => _imageFile = null),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 56,
              color: Theme.of(context).primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.addFromUrl,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white70 
                    : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _discountCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final String fileName = 'notifications/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = ref.putFile(_imageFile!);
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _sendNotification() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterTitleAndMessage)),
      );
      return;
    }

    // Add this check before sending notification
    if (!_sendToAllUsers && _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectUsersFirst),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      if (_imageFile != null) {
        // Show upload progress
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.uploadingImage)),
        );
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      // Create notification data
      final additionalData = {
        'type': _selectedType,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (_selectedType == 'promotion' && _discountCodeController.text.isNotEmpty)
          'discountCode': _discountCodeController.text,
      };

      bool success = false;
      
      if (_sendToAllUsers) {
        success = await NotificationService.sendToAllUsers(
          title: _titleController.text,
          message: _messageController.text,
          additionalData: additionalData,
        );
      } else if (_selectedUsers.isNotEmpty) {
        success = await NotificationService.sendToUsers(
          userIds: _selectedUsers,
          title: _titleController.text,
          message: _messageController.text,
          additionalData: additionalData,
        );
      } else {
        throw Exception('No users selected for targeted notification');
      }

      if (!success) {
        throw Exception('Failed to send notification through backend');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.notificationSent),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _titleController.clear();
        _messageController.clear();
        _discountCodeController.clear();
        setState(() {
          _imageFile = null;
          _selectedUsers = [];
          _selectedType = 'general';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.notificationError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationManagement),
        backgroundColor: themeColor,
        elevation: isDark ? 0 : 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[900]!,
                    Colors.grey[850]!,
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[100]!,
                    Colors.white,
                  ],
                ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: isDark ? 1 : 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notifications_active, color: themeColor, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            l10n.newNotification,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      // Image picker section
                      _buildImagePicker(),
                      const SizedBox(height: 25),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: l10n.notificationTitle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: themeColor, width: 2),
                          ),
                          prefixIcon: Icon(Icons.title, color: themeColor),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: l10n.notificationMessage,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: themeColor, width: 2),
                          ),
                          prefixIcon: Icon(Icons.message, color: themeColor),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Notification Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: themeColor, width: 2),
                          ),
                          prefixIcon: Icon(Icons.category, color: themeColor),
                        ),
                        items: [
                          DropdownMenuItem(value: 'general', child: Text('General')),
                          DropdownMenuItem(value: 'promotion', child: Text('Promotion')),
                          DropdownMenuItem(value: 'order', child: Text('Order')),
                          DropdownMenuItem(value: 'system', child: Text('System')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                      if (_selectedType == 'promotion') ...[
                        const SizedBox(height: 20),
                        TextField(
                          controller: _discountCodeController,
                          decoration: InputDecoration(
                            labelText: 'Discount Code (Optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: themeColor, width: 2),
                            ),
                            prefixIcon: Icon(Icons.local_offer, color: themeColor),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? Colors.grey[850] : Colors.grey[100],
                        ),
                        child: SwitchListTile(
                          title: Text(
                            l10n.sendToAllUsers,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          value: _sendToAllUsers,
                          onChanged: (bool value) {
                            setState(() {
                              _sendToAllUsers = value;
                            });
                          },
                          activeColor: themeColor,
                        ),
                      ),
                      if (!_sendToAllUsers) ...[
                        const SizedBox(height: 20),
                        _buildUserSelection(),
                      ],
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendNotification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: isDark ? 1 : 3,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.send, color: Colors.white),
                                    const SizedBox(width: 10),
                                    Text(
                                      l10n.sendNotification,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}