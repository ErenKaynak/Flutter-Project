import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoUploaderPage extends StatefulWidget {
  const PhotoUploaderPage({super.key});

  @override
  State<PhotoUploaderPage> createState() => _PhotoUploaderPageState();
}

class _PhotoUploaderPageState extends State<PhotoUploaderPage> {
  File? _image;
  Uint8List? _webImage;
  String? _uploadedImageUrl;
  bool _isLoading = false;

  final String clientId = '025f0e0a98cb8a7';

  int _retryCount = 0;
  static const int _maxRetries = 3;

  final List<Map<String, String>> _uploadHistory = [];
  ScrollController _historyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUploadHistory();
  }

  Future<bool> _wait(int seconds) async {
    try {
      await Future.delayed(Duration(seconds: seconds));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        // Handle web platform
        var bytes = await image.readAsBytes();
        setState(() {
          _webImage = bytes;
          _image = null;
          _uploadedImageUrl = null;
        });
      } else {
        // Handle mobile platforms
        setState(() {
          _image = File(image.path);
          _webImage = null;
          _uploadedImageUrl = null;
        });
      }
    }
  }

  Future<void> _loadUploadHistory() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('imageUploadHistory')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _uploadHistory.clear();
        for (var doc in snapshot.docs) {
          _uploadHistory.add({
            'url': doc.data()['url'],
            'timestamp': doc.data()['timestamp'].toDate().toString(),
          });
        }
      });
    } catch (e) {
      print('Error loading upload history: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null && _webImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = kIsWeb ? _webImage! : await _image!.readAsBytes();
      
      if (bytes.length > 10 * 1024 * 1024) {
        throw Exception('Image size exceeds 10MB limit');
      }

      final base64Image = base64Encode(bytes);
      print('Attempting to upload image...');
      print('Image size: ${bytes.length} bytes');

      // Use form data instead of JSON
      var request = http.MultipartRequest('POST', Uri.parse('https://api.imgur.com/3/image'));
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Client-ID $clientId',
      });

      // Add form fields
      request.fields['image'] = base64Image;
      request.fields['type'] = 'base64';

      // Send the request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Upload request timed out');
        },
      );

      // Get the response
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final imageUrl = responseData['data']['link'];
          
          // Save to Firestore
          await FirebaseFirestore.instance
              .collection('imageUploadHistory')
              .add({
            'url': imageUrl,
            'timestamp': FieldValue.serverTimestamp(),
          });

          setState(() {
            _uploadedImageUrl = imageUrl;
            _isLoading = false;
            // Add to history
            _uploadHistory.insert(0, {
              'url': imageUrl,
              'timestamp': DateTime.now().toString(),
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!')),
          );
          return;
        }
        throw Exception(responseData['data']['error'] ?? 'Unknown error occurred');
      }

      // Handle specific error cases
      String errorMessage;
      switch (response.statusCode) {
        case 429:
          errorMessage = 'Rate limit exceeded. Please wait a few minutes and try again.';
          break;
        case 400:
          errorMessage = 'Bad request. Please check your image format.';
          break;
        case 401:
          errorMessage = 'Unauthorized. Please check your client ID.';
          break;
        case 403:
          errorMessage = 'Forbidden. Please check your API access.';
          break;
        case 413:
          errorMessage = 'Image is too large. Please choose a smaller image.';
          break;
        default:
          errorMessage = 'Upload failed with status code: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    } on SocketException catch (e) {
      print('Network error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please check your internet connection.')),
      );
    } on TimeoutException {
      print('Request timed out');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload timed out. Please try again.')),
      );
    } catch (e) {
      print('Upload error: $e');
      setState(() {
        _isLoading = false;
      });

      if (e.toString().contains('429') && _retryCount < _maxRetries) {
        _retryCount++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rate limited. Retrying in ${_retryCount * 5} seconds...')),
        );
        if (await _wait(_retryCount * 5)) {
          return _uploadImage();
        }
      }

      _retryCount = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshots = await FirebaseFirestore.instance
          .collection('imageUploadHistory')
          .get();
      
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      setState(() => _uploadHistory.clear());
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload history cleared'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing history'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
      _webImage = null;
      _uploadedImageUrl = null;
    });
  }

  @override
  void dispose() {
    _historyScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Uploader'),
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: isDark ? 0 : 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [Colors.red.shade900, Colors.grey.shade900]
                    : [Colors.red.shade500, Colors.red.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Upload Images",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Select and upload images to the api we providedto you",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Image Preview Card
            if (_image != null || _webImage != null)
              Card(
                elevation: isDark ? 1 : 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? Colors.grey.shade800 : Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "Selected Image",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? Colors.grey.shade900 : Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb && _webImage != null
                            ? Image.memory(
                                _webImage!,
                                fit: BoxFit.contain,
                              )
                            : _image != null
                                ? Image.file(
                                    _image!,
                                    fit: BoxFit.contain,
                                  )
                                : null,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _uploadImage,
                              icon: _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(Icons.upload),
                              label: Text(_isLoading ? 'Uploading...' : 'Upload'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _removeImage,
                              icon: Icon(Icons.delete),
                              label: Text('Remove'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                                foregroundColor: isDark ? Colors.white : Colors.black87,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Select Image Button
            if (_image == null && _webImage == null)
              Card(
                elevation: isDark ? 1 : 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? Colors.grey.shade800 : Colors.white,
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: Colors.red.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Select an Image",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Tap to choose an image from your gallery",
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Uploaded URL Card
            if (_uploadedImageUrl != null) ...[
              SizedBox(height: 24),
              Card(
                elevation: isDark ? 1 : 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? Colors.grey.shade800 : Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Uploaded Image URL",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                _uploadedImageUrl!,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _uploadedImageUrl!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('URL copied to clipboard'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Upload History Card
            if (_uploadHistory.isNotEmpty) ...[
              SizedBox(height: 24),
              Card(
                elevation: isDark ? 1 : 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? Colors.grey.shade800 : Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Upload History",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.delete_sweep),
                            label: Text("Clear"),
                            onPressed: _uploadHistory.isEmpty ? null : _clearHistory,
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 200, // Fixed height for history section
                        child: ListView.builder(
                          controller: _historyScrollController,
                          itemCount: _uploadHistory.length,
                          itemBuilder: (context, index) {
                            final item = _uploadHistory[index];
                            return Card(
                              color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                              margin: EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: item['url']!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('Link copied to clipboard'),
                                        ],
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 2),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                child: ListTile(
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(item['url']!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    item['url']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'Uploaded: ${DateTime.parse(item['timestamp']!).toLocal().toString().split('.')[0]}',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  trailing: Icon(Icons.copy, size: 20, color: isDark ? Colors.white54 : Colors.grey.shade600),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}