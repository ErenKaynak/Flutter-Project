import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;

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

  Future<void> _uploadImage() async {
    if (_image == null && _webImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = kIsWeb ? _webImage! : await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgur.com/3/image'),
        headers: {
          'Authorization': 'Client-ID $clientId',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'image': base64Image,
          'type': 'base64',
        },
      );

      String errorMessage;
      switch (response.statusCode) {
        case 200:
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            setState(() {
              _uploadedImageUrl = responseData['data']['link'];
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded successfully!')),
            );
            return;
          }
          errorMessage = responseData['data']['error'] ?? 'Unknown error occurred';
          break;
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
        default:
          errorMessage = 'Upload failed with status code: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    } catch (e) {
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
      
      _retryCount = 0; // Reset retry count
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
      print('Upload error: $e');
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
                        child: SelectableText(
                          _uploadedImageUrl!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
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