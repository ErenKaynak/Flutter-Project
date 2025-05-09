import 'dart:io';

import 'package:engineering_project/assets/AI/api_config.dart';
import 'package:engineering_project/assets/components/cart_manager.dart';
import 'package:engineering_project/models/product.dart';
import 'package:engineering_project/pages/cart_page.dart';
import 'package:engineering_project/screens/cart_screen.dart';
import 'package:engineering_project/pages/product-detail-page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:engineering_project/providers/cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

enum SpecialColorTheme { red, blue, green }

MaterialColor getThemeColor(SpecialColorTheme theme) {
  switch (theme) {
    case SpecialColorTheme.red:
      return Colors.red;
    case SpecialColorTheme.blue:
      return Colors.blue;
    case SpecialColorTheme.green:
      return Colors.green;
    default:
      return Colors.red;
  }
}

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  DateTime? _lastRequestTime;
  String? _userProfileImage;
  bool _isAIEnabled = true;

  AnimationController? _typingAnimation;

  final List<String> _conversationStarters = [
    'I need assistance',
    'Recommend me the cheapest PC build',
    'Looking for a gaming PC build',
    // Admin-only starters will be shown conditionally
    'Add new product',
    'Update product',
  ];

  final String systemPrompt = '''
You are a knowledgeable PC hardware assistant. Help users with PC builds using only available components.
- Only recommend products that we have in stock
- Focus on compatibility between components
- Consider the user's budget and intended use (gaming, work, etc.)
- If we don't have a specific component, suggest alternatives from our inventory
- Don't mention or suggest products we don't have in stock
''';

  // OpenRouter Configuration
  static const String _openRouterApiKey =
      APIConfig.ApiKey; // Replace with your key
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  // Mevcut değişkenlerin yanına ekleyin
  SpecialColorTheme? _selectedTheme;

  // Add these variables in _AIChatScreenState class
  String? _currentProductId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _typingAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    _testFirebaseConnection();
    _loadUserProfile();
    _checkAIAvailability();
    _loadSelectedTheme();
    _checkAdminStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Precache images after dependencies are ready
    _precacheImages();

    // AI settings listener
    FirebaseFirestore.instance
        .collection('settings')
        .doc('ai_settings')
        .snapshots()
        .listen((doc) {
          if (mounted) {
            setState(() {
              _isAIEnabled =
                  doc.exists ? (doc.data()?['isEnabled'] ?? true) : true;
            });
          }
        });
  }

  // Create a separate method for image precaching
  void _precacheImages() {
    const assetPaths = [
      'lib/assets/Images/Mascot/mascot-default.png',
      'lib/assets/Images/Mascot/mascot-crossedarms.png',
      'lib/assets/Images/Mascot/mascot-wave.png',
    ];

    for (final path in assetPaths) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void dispose() {
    _typingAnimation?.dispose();
    _messageController.dispose();
    _currentProductId = null;
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userData =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userData.exists) {
          setState(() {
            _userProfileImage = userData.data()?['profileImageUrl'];
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
      }
    }
  }

  Future<void> _checkAIAvailability() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('ai_settings')
              .get();

      if (mounted) {
        setState(() {
          _isAIEnabled = doc.exists ? (doc.data()?['isEnabled'] ?? true) : true;
        });
      }
    } catch (e) {
      print('Error checking AI availability: $e');
    }
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsappUrl = Uri.parse('http://wa.me/+905469549755');
    if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  // Tema yükleme fonksiyonunu ekleyin
  Future<void> _loadSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('selectedTheme');
    if (themeString != null) {
      setState(() {
        _selectedTheme = SpecialColorTheme.values.firstWhere(
          (e) => e.toString() == 'SpecialColorTheme.$themeString',
          orElse: () => SpecialColorTheme.blue,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add this at the start of build method
    _debugAdminStatus();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor =
        _selectedTheme != null ? getThemeColor(_selectedTheme!) : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Tommy'),
        backgroundColor:
            isDark
                ? Colors.black
                : (_selectedTheme != null
                    ? getThemeColor(_selectedTheme!)
                    : Theme.of(context).primaryColor),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.grey[50],
              ),
              child:
                  _messages.isEmpty
                      ? _buildConversationStarters() // Show starters when no messages
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          final message =
                              _messages[_messages.length - 1 - index];
                          return _buildMessage(message);
                        },
                      ),
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildImageUploadField(), // Add this line
        ],
      ),
    );
  }

  Widget _buildConversationStarters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor =
        _selectedTheme != null ? getThemeColor(_selectedTheme!) : Colors.red;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(24),
        margin: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.grey.shade800.withOpacity(0.7)
                  : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'lib/assets/Images/Mascot/mascot-wave.png',
              width: 120,
              height: 120,
            ),
            SizedBox(height: 16),
            Text(
              'How can I help you today?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children:
                  _getFilteredStarters().map((starter) {
                    return ElevatedButton(
                      onPressed: () {
                        if (starter == 'Add new product') {
                          _showAddProductDialog();
                        } else if (starter == 'I need assistance') {
                          _launchWhatsApp();
                        } else if (starter == 'Update product') {
                          _showProductSearchDialog();
                        } else {
                          _messageController.text = starter;
                          _handleSubmitted(starter);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? themeColor.shade700 : themeColor.shade400,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        starter,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor =
        _selectedTheme != null ? getThemeColor(_selectedTheme!) : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isDark ? themeColor.shade900 : themeColor.shade100,
            child: Image.asset(
              'lib/assets/Images/Mascot/mascot-default.png',
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                return frame == null ? const SizedBox() : child;
              },
              errorBuilder:
                  (context, error, stackTrace) => const Icon(Icons.error),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [_buildDot(1), _buildDot(2), _buildDot(3)]),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimation!,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        double opacity = sin(
          (_typingAnimation!.value * pi * 2) - (index * pi / 2),
        );
        opacity = opacity.clamp(0.3, 1.0);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.red.shade400).withOpacity(
              opacity,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor =
        _selectedTheme != null ? getThemeColor(_selectedTheme!) : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                message.isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser)
                CircleAvatar(
                  backgroundColor:
                      isDark ? themeColor.shade900 : themeColor.shade100,
                  child: Image.asset(
                    'lib/assets/Images/Mascot/mascot-crossedarms.png',
                    width: 37,
                    height: 37,
                  ),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        message.isUser
                            ? (isDark
                                ? themeColor.shade900
                                : themeColor.shade400)
                            : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(message.isUser ? 20 : 0),
                      topRight: Radius.circular(message.isUser ? 0 : 20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imageUrl != null)
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: 200,
                            maxWidth: 300,
                          ),
                          margin: EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              message.imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            ),
                          ),
                        ),
                      Text(
                        message.text,
                        style: TextStyle(
                          color:
                              message.isUser
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (message.isUser)
                CircleAvatar(
                  backgroundColor:
                      isDark ? themeColor.shade900 : themeColor.shade100,
                  backgroundImage:
                      _userProfileImage != null
                          ? NetworkImage(_userProfileImage!)
                          : null,
                  child:
                      _userProfileImage == null
                          ? Icon(
                            Icons.person,
                            color:
                                isDark ? Colors.white70 : themeColor.shade400,
                          )
                          : null,
                ),
            ],
          ),

          // Product recommendations section
          if (!message.isUser && message.recommendedProducts != null)
            Container(
              height: 200,
              margin: EdgeInsets.only(top: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: message.recommendedProducts!.length,
                itemBuilder: (context, index) {
                  final product = message.recommendedProducts![index];
                  return Card(
                    margin: EdgeInsets.only(right: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ProductDetailPage(productId: product.id),
                          ),
                        );
                      },
                      child: Container(
                        width: 160,
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.imageUrl.isNotEmpty)
                              Expanded(
                                child: Hero(
                                  tag: 'product-${product.id}',
                                  child: Image.network(
                                    product.imageUrl,
                                    fit: BoxFit.cover,
                                    frameBuilder: (
                                      context,
                                      child,
                                      frame,
                                      wasSynchronouslyLoaded,
                                    ) {
                                      if (wasSynchronouslyLoaded) return child;
                                      return AnimatedOpacity(
                                        opacity: frame == null ? 0 : 1,
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        curve: Curves.easeOut,
                                        child: child,
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.error),
                                            ),
                                    cacheWidth: 320, // Add width constraint
                                    cacheHeight: 240, // Add height constraint
                                  ),
                                ),
                              ),
                            SizedBox(height: 8),
                            Text(
                              product.name,
                              style: TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '\₺${product.price.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.green),
                            ),
                            // Update the TextButton in product card
                            TextButton(
                              onPressed: () => _addToCart(product),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    _selectedTheme != null
                                        ? getThemeColor(_selectedTheme!)
                                        : Colors.red,
                              ),
                              child: Text('Add to Cart'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: 8),
          if (!message.isUser &&
              message.recommendedProducts != null &&
              message.recommendedProducts!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton.icon(
                onPressed:
                    () => _showAddToCartDialog(message.recommendedProducts!),
                // Update the "Add All Recommended Products to Cart" button
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark
                          ? (_selectedTheme != null
                              ? getThemeColor(_selectedTheme!).shade900
                              : Colors.red.shade900)
                          : (_selectedTheme != null
                              ? getThemeColor(_selectedTheme!).shade400
                              : Colors.red.shade400),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: Icon(Icons.shopping_cart, color: Colors.white),
                label: Text('Add All Recommended Products to Cart'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleSubmitted(String text, {File? image}) async {
    if (text.trim().isEmpty && image == null) return;

    setState(() {
      if (text.isNotEmpty) {
        _messages.add(ChatMessage(text: text, isUser: true));
      }
      _messageController.clear();
      _isTyping = true;
    });

    try {
      if (_currentProductId != null && image != null) {
        setState(() {
          _messages.add(ChatMessage(text: 'Uploading image...', isUser: true));
        });

        final imageUrl = await _uploadProductImage(image);
        if (imageUrl != null) {
          await FirebaseFirestore.instance
              .collection('products')
              .doc(_currentProductId)
              .update({
                'imagePath': imageUrl,
                'images': FieldValue.arrayUnion([imageUrl]),
              });

          _addMessage(
            ChatMessage(
              text: 'Image uploaded and added to the product successfully!',
              isUser: false,
            ),
          );

          // Reset product creation state
          setState(() {
            _currentProductId = null;
          });
          return;
        } else {
          _addMessage(
            ChatMessage(
              text: 'Failed to upload image. Please try again.',
              isUser: false,
            ),
          );
          return;
        }
      }

      if (text.toLowerCase().contains('add new product') ||
          text.toLowerCase().contains('update product')) {
        await _handleProductCreation(text);
      } else {
        final (response, recommendations) = await _getAIResponse(text);
        _addMessage(
          ChatMessage(
            text: response,
            isUser: false,
            recommendedProducts:
                recommendations.isNotEmpty ? recommendations : null,
          ),
        );
      }
    } catch (e) {
      print('Error in _handleSubmitted: $e');
      _addMessage(
        ChatMessage(
          text: 'An error occurred. Please try again.',
          isUser: false,
        ),
      );
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  Future<(String, List<Product>)> _getAIResponse(String message) async {
    if (!_isAIEnabled) {
      return Future.value((
        'I\'m currently on vacation!! Try to talk to me later :P',
        <Product>[],
      ));
    }

    try {
      // Check if message contains product-related keywords
      bool shouldRecommend =
          message.toLowerCase().contains('recommend') ||
          message.toLowerCase().contains('pc build') ||
          message.toLowerCase().contains('build') ||
          message.toLowerCase().contains('suggest') ||
          message.toLowerCase().contains('looking for');

      // Only get recommendations if user specifically asked
      final List<Product> recommendations =
          shouldRecommend
              ? await _getProductRecommendations(message, {
                'cpu_brand':
                    message.toLowerCase().contains('intel') ? 'intel' : 'amd',
                'use_case':
                    message.toLowerCase().contains('gaming')
                        ? 'gaming'
                        : 'work',
              })
              : [];

      final response = await http.post(
        Uri.parse(APIConfig.openRouterUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${APIConfig.ApiKey}',
          'HTTP-Referer': 'http://localhost',
          'X-Title': 'AI Chat Assistant',
        },
        body: jsonEncode({
          'model': 'deepseek/deepseek-prover-v2:free',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': message},
          ],
        }),
      );

      if (response.statusCode != 200) {
        print('API error ${response.statusCode}: ${response.body}');
        throw Exception('API request failed');
      }

      final data = jsonDecode(response.body);
      return (
        data['choices'][0]['message']['content'] as String,
        recommendations,
      );
    } catch (e, stackTrace) {
      print('Error in API request: $e');
      print('Stack trace: $stackTrace');

      // Return fallback response without recommendations unless specifically asked
      return (
        APIConfig.fallbackResponses[Random().nextInt(
          APIConfig.fallbackResponses.length,
        )],
        <Product>[], // Explicitly typed empty list as List<Product>
      );
    }
  }

  void _addToCart(Product product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add items to cart')),
      );
      return;
    }

    try {
      // Convert Product to CartItem format
      final cartItem = {
        'id': product.id,
        'name': product.name,
        'price': product.price.toString(),
        'imagePath': product.imageUrl,
        'quantity': 1,
      };

      // Add to Firestore cart collection
      await FirebaseFirestore.instance
          .collection('cart')
          .doc(user.uid)
          .collection('userCart')
          .doc(product.id)
          .set(cartItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => const CartPage()));
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding to cart: $e')));
    }
  }

  void _addAllToCart(List<Product> products) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add items to cart')),
      );
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final cartRef = FirebaseFirestore.instance
          .collection('cart')
          .doc(user.uid)
          .collection('userCart');

      for (final product in products) {
        if (!product.id.startsWith('empty_')) {
          final cartItem = {
            'id': product.id,
            'name': product.name,
            'price': product.price.toString(),
            'imagePath': product.imageUrl,
            'quantity': 1,
          };
          batch.set(cartRef.doc(product.id), cartItem);
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All recommended products added to cart'),
            action: SnackBarAction(
              label: 'VIEW CART',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding items to cart: $e')),
        );
      }
    }
  }

  Future<List<Product>> _getProductRecommendations(
    String message,
    Map<String, String> preferences,
  ) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final List<Product> recommendations = [];

      print(
        'Starting product recommendations search with preferences: $preferences',
      );

      // Get all products and filter by availability
      final QuerySnapshot allProducts =
          await firestore
              .collection('products')
              .where('stock', isGreaterThan: 0) // Only get products in stock
              .get();

      print('Found ${allProducts.docs.length} available products');

      // Group available products by category
      Map<String, List<DocumentSnapshot>> productsByCategory = {};
      for (var doc in allProducts.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String? ?? 'Unknown';
        productsByCategory.putIfAbsent(category, () => []).add(doc);
      }

      // CPU Selection Logic
      if (productsByCategory.containsKey('CPU\'s')) {
        var cpus = productsByCategory['CPU\'s']!;

        // Filter by brand if specified
        if (preferences['cpu_brand'] != null) {
          cpus =
              cpus.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] as String).toLowerCase();
                return name.contains(preferences['cpu_brand']!.toLowerCase());
              }).toList();
        }

        // Sort by price if it's a budget build
        if (message.toLowerCase().contains('budget') ||
            message.toLowerCase().contains('cheap')) {
          cpus.sort((a, b) {
            final priceA = (a.data() as Map<String, dynamic>)['price'] as num;
            final priceB = (b.data() as Map<String, dynamic>)['price'] as num;
            return priceA.compareTo(priceB);
          });
        }

        if (cpus.isNotEmpty) {
          final doc = cpus.first;
          final data = doc.data() as Map<String, dynamic>;
          recommendations.add(
            Product(
              id: doc.id,
              name: data['name'],
              category: 'CPU\'s',
              price: (data['price'] as num).toDouble(),
              description: data['description'] ?? '',
              imageUrl: data['imagePath'] ?? '',
              stock: data['stock'] as int? ?? 0, // Add stock field
            ),
          );
        }
      }

      // Only proceed with other components if we found a CPU
      if (recommendations.isEmpty) {
        return []; // Return empty list if no CPU found
      }

      // Get CPU brand for compatibility
      final cpuBrand =
          recommendations.first.name.toLowerCase().contains('intel')
              ? 'intel'
              : 'amd';

      // Compatible Motherboard Selection
      if (productsByCategory.containsKey('Motherboards')) {
        var motherboards =
            productsByCategory['Motherboards']!.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] as String).toLowerCase();
              return name.contains(cpuBrand);
            }).toList();

        if (motherboards.isNotEmpty) {
          final doc = motherboards[0];
          final data = doc.data() as Map<String, dynamic>;
          recommendations.add(
            Product(
              id: doc.id,
              name: data['name'],
              category: 'Motherboards',
              price: (data['price'] as num).toDouble(),
              description: data['description'] ?? '',
              imageUrl: data['imagePath'] ?? '',
              stock: data['stock'] as int? ?? 0, // Add stock field
            ),
          );
        }
      }

      // Add other components based on use case
      final isGaming = preferences['use_case'] == 'gaming';
      final isBudget =
          message.toLowerCase().contains('budget') ||
          message.toLowerCase().contains('cheap');

      // Define required categories
      final requiredCategories = ['RAM\'s', 'Storage', 'PSU', 'Case'];
      if (isGaming) requiredCategories.insert(1, 'GPU\'s');

      for (final category in requiredCategories) {
        if (!productsByCategory.containsKey(category)) continue;

        var products = productsByCategory[category]!;

        // Sort by price for budget builds
        if (isBudget) {
          products.sort((a, b) {
            final priceA = (a.data() as Map<String, dynamic>)['price'] as num;
            final priceB = (b.data() as Map<String, dynamic>)['price'] as num;
            return priceA.compareTo(priceB);
          });
        }

        // Special handling for gaming GPUs
        if (category == 'GPU\'s' && isGaming && !isBudget) {
          products =
              products.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final price = (data['price'] as num).toDouble();
                return price >= 300; // Gaming GPUs threshold
              }).toList();
        }

        if (products.isNotEmpty) {
          final doc = products.first;
          final data = doc.data() as Map<String, dynamic>;
          recommendations.add(
            Product(
              id: doc.id,
              name: data['name'],
              category: category,
              price: (data['price'] as num).toDouble(),
              description: data['description'] ?? '',
              imageUrl: data['imagePath'] ?? '',
              stock: data['stock'] as int? ?? 0, // Add stock field
            ),
          );
        }
      }

      return recommendations;
    } catch (e) {
      print('Error in _getProductRecommendations: $e');
      return [];
    }
  }

  Future<void> _testFirebaseConnection() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final QuerySnapshot snapshot =
          await firestore.collection('products').limit(1).get();
      print(
        'Firebase connection test: ${snapshot.docs.length} documents found',
      );
      if (snapshot.docs.isNotEmpty) {
        print('Sample document data: ${snapshot.docs.first.data()}');
      }
    } catch (e) {
      print('Firebase connection test failed: $e');
    }
  }

  // Add this method to show the confirmation dialog
  void _showAddToCartDialog(List<Product> products) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor =
        _selectedTheme != null ? getThemeColor(_selectedTheme!) : Colors.red;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade900
                  : Colors.white,
          title: Text(
            'Add to Cart',
            style: TextStyle(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
            ),
          ),
          content: Text(
            'Do you want to add all recommended products to your cart?',
            style: TextStyle(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : themeColor.shade700,
              ),
              child: Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addAllToCart(products);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? themeColor.shade900 : themeColor.shade400,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  // Add this function in _AIChatScreenState class
  Future<bool> _isAdminUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      // Check if role is "admin" instead of isAdmin field
      return userDoc.data()?['role'] == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Add this method to filter starters based on admin status
  List<String> _getFilteredStarters() {
    print('Getting filtered starters. Is admin: $_isAdmin'); // Debug print
    final List<String> starters = List.from(_conversationStarters);

    if (!_isAdmin) {
      return starters
          .where(
            (starter) =>
                !starter.toLowerCase().contains('add new product') &&
                !starter.toLowerCase().contains('update product'),
          )
          .toList();
    }

    return starters;
  }

  // Add this method to handle cross-platform image upload
  Future<String?> _uploadProductImage(dynamic imageSource) async {
    if (imageSource == null) return null;

    try {
      List<int> imageBytes;

      if (kIsWeb) {
        if (imageSource is XFile) {
          // Handle XFile for web
          imageBytes = await imageSource.readAsBytes();
        } else if (imageSource is File) {
          // Handle File for web
          imageBytes = await imageSource.readAsBytes();
        } else {
          throw Exception('Unsupported image source type for web');
        }
      } else {
        if (imageSource is File) {
          // Handle File for mobile
          imageBytes = await imageSource.readAsBytes();
        } else if (imageSource is XFile) {
          // Handle XFile for mobile
          imageBytes = await imageSource.readAsBytes();
        } else {
          throw Exception('Unsupported image source type for mobile');
        }
      }

      // Check image size
      if (imageBytes.length > 10 * 1024 * 1024) {
        throw Exception('Image size exceeds 10MB limit');
      }

      final base64Image = base64Encode(imageBytes);

      // Update the API endpoint to use HTTPS
      final response = await http.post(
        Uri.parse('https://api.imgur.com/3/image'),
        headers: {
          'Authorization': 'Client-ID ${APIConfig.imgurClientId}',
          'Content-Type': 'application/json',
          // Add CORS headers for web
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST',
          'Access-Control-Allow-Headers': 'Authorization, Content-Type',
        },
        body: jsonEncode({'image': base64Image, 'type': 'base64'}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('Image upload successful: ${responseData['data']['link']}');
          return responseData['data']['link'];
        }
      }
      throw Exception(
        'Image upload failed with status: ${response.statusCode}',
      );
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
      return null;
    }
  }

  Future<void> _handleProductCreation(String message) async {
    if (!_isAdmin) {
      _addMessage(
        ChatMessage(
          text: 'Sorry, only admin users can add products.',
          isUser: false,
        ),
      );
      return;
    }

    if (message.toLowerCase().contains('add new product')) {
      _addMessage(
        ChatMessage(
          text:
              'Please provide the product details in the following format:\n'
              'Name: [Product Name]\n'
              'Price: [Price in TRY]\n'
              'Category: [CPU/GPU/RAM/Storage/Motherboard/Case/PSU]\n'
              'Description: [Product Description]\n'
              'Stock: [Stock Quantity]\n\n'
              'You can also send an image of the product.',
          isUser: false,
        ),
      );
      return;
    }

    // Parse product details from message
    final Map<String, String> productDetails = {};
    final RegExp detailsRegex = RegExp(r'(\w+):\s*([^\n]+)');
    final matches = detailsRegex.allMatches(message);

    for (var match in matches) {
      String key = match.group(1)?.toLowerCase() ?? '';
      String value = match.group(2)?.trim() ?? '';
      productDetails[key] = value;
    }

    // Validate required fields
    if (!_validateProductDetails(productDetails)) {
      _addMessage(
        ChatMessage(
          text:
              'Please provide all required product details in the correct format.',
          isUser: false,
        ),
      );
      return;
    }

    try {
      final product = {
        'name': productDetails['name'],
        'price': double.parse(productDetails['price']!),
        'category': productDetails['category'],
        'description': productDetails['description'] ?? '',
        'stock': int.parse(productDetails['stock'] ?? '0'),
        'imagePath': '',
        'images': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('products')
          .add(product);

      setState(() {
        _currentProductId = docRef.id;
      });

      _addMessage(
        ChatMessage(
          text:
              'Product created successfully! You can now send images for this product.',
          isUser: false,
        ),
      );
    } catch (e) {
      _addMessage(
        ChatMessage(text: 'Error creating product: $e', isUser: false),
      );
    }
  }

  bool _validateProductDetails(Map<String, String> details) {
    // Required fields
    final requiredFields = ['name', 'price', 'category'];
    for (var field in requiredFields) {
      if (!details.containsKey(field) || details[field]!.isEmpty) {
        return false;
      }
    }

    // Validate price format
    if (double.tryParse(details['price'] ?? '') == null) {
      return false;
    }

    // Validate category
    final validCategories = [
      "CPU's",
      "GPU's",
      "RAM's",
      "Storage",
      "Motherboards",
      "Cases",
      "PSUs",
    ];
    if (!validCategories.contains(details['category'])) {
      return false;
    }

    // Validate stock if provided
    if (details.containsKey('stock') &&
        int.tryParse(details['stock']!) == null) {
      return false;
    }

    return true;
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.insert(0, message);
      _isTyping = false;
    });
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isAdmin = false;
      });
      return;
    }

    try {
      // Listen to real-time updates of user's role
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
            if (mounted) {
              setState(() {
                // Check role field instead of isAdmin
                _isAdmin = snapshot.data()?['role'] == 'admin';
                print('Admin status updated: $_isAdmin');
                print('User role: ${snapshot.data()?['role']}');
              });
            }
          });
    } catch (e) {
      print('Error checking admin status: $e');
      setState(() {
        _isAdmin = false;
      });
    }
  }

  void _debugAdminStatus() {
    final user = FirebaseAuth.instance.currentUser;
    print('Current user: ${user?.uid}');
    print('Is admin: $_isAdmin');

    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((
        doc,
      ) {
        print('User data: ${doc.data()}');
        print('User role: ${doc.data()?['role']}');
        print('Admin status from role: ${doc.data()?['role'] == 'admin'}');
      });
    }
  }

  // Add this method to the _AIChatScreenState class
  void _showAddProductDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController stockController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String? selectedCategory;
    String? mainImagePath;
    List<String> additionalImagePaths = [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor =
        _selectedTheme != null ? getThemeColor(_selectedTheme!) : Colors.red;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Product',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            SizedBox(height: 20),
                            // Main Image Selection
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: themeColor.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child:
                                  mainImagePath != null
                                      ? Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              13,
                                            ),
                                            child: Image.network(
                                              mainImagePath!,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                setState(
                                                  () => mainImagePath = null,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                      : InkWell(
                                        onTap: () async {
                                          final imageUrl =
                                              await _pickAndUploadImage();
                                          if (imageUrl != null) {
                                            setState(
                                              () => mainImagePath = imageUrl,
                                            );
                                          }
                                        },
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                size: 40,
                                                color: themeColor,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Add Main Image',
                                                style: TextStyle(
                                                  color: themeColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                            ),
                            SizedBox(height: 16),
                            // Additional Images
                            Container(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: max(
                                  3,
                                  additionalImagePaths.length,
                                ), // Use max to show at least 3 slots
                                itemBuilder: (context, index) {
                                  final hasImage =
                                      index < additionalImagePaths.length;
                                  return Container(
                                    width: 100,
                                    margin: EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: themeColor.withOpacity(0.5),
                                      ),
                                    ),
                                    child:
                                        hasImage
                                            ? Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                  child: Image.network(
                                                    additionalImagePaths[index],
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Center(
                                                          child: Icon(
                                                            Icons.error,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        additionalImagePaths
                                                            .removeAt(index);
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            )
                                            : InkWell(
                                              onTap: () async {
                                                final imageUrl =
                                                    await _pickAndUploadImage();
                                                if (imageUrl != null) {
                                                  setState(() {
                                                    additionalImagePaths.add(
                                                      imageUrl,
                                                    );
                                                  });
                                                }
                                              },
                                              child: Center(
                                                child: Icon(
                                                  Icons.add_photo_alternate,
                                                  color: themeColor,
                                                ),
                                              ),
                                            ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 16),
                            // Product Details Fields
                            _buildTextField(
                              controller: nameController,
                              label: 'Product Name',
                              isDark: isDark,
                            ),
                            SizedBox(height: 12),
                            _buildTextField(
                              controller: priceController,
                              label: 'Price (TRY)',
                              keyboardType: TextInputType.number,
                              isDark: isDark,
                            ),
                            SizedBox(height: 12),
                            _buildTextField(
                              controller: stockController,
                              label: 'Stock Quantity',
                              keyboardType: TextInputType.number,
                              isDark: isDark,
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade300,
                                ),
                              ),
                              child: FutureBuilder<List<String>>(
                                future: _fetchCategories(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final categories =
                                      snapshot.data ??
                                      [
                                        "CPU's",
                                        "GPU's",
                                        "RAM's",
                                        "Storage",
                                        "Motherboards",
                                        "Cases",
                                        "PSUs",
                                      ];

                                  // Check if selectedCategory exists in the categories list
                                  if (selectedCategory != null &&
                                      !categories.contains(selectedCategory)) {
                                    // If category doesn't exist anymore, reset selection to null
                                    selectedCategory = null;
                                  }

                                  return DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedCategory,
                                      isExpanded: true,
                                      hint: Text('Select Category'),
                                      items:
                                          categories.map((String category) {
                                            return DropdownMenuItem(
                                              value: category,
                                              child: Text(category),
                                            );
                                          }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(
                                          () => selectedCategory = newValue,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildTextField(
                              controller: descriptionController,
                              label: 'Description',
                              maxLines: 3,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              if (_validateProductInput(
                                nameController.text,
                                priceController.text,
                                stockController.text,
                                selectedCategory,
                                mainImagePath,
                              )) {
                                await _saveProduct(
                                  nameController.text,
                                  double.parse(priceController.text),
                                  int.parse(stockController.text),
                                  selectedCategory!,
                                  descriptionController.text,
                                  mainImagePath!,
                                  additionalImagePaths,
                                );
                                Navigator.pop(context);
                              }
                            },
                            child: Text('Add Product'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Add these helper methods to _AIChatScreenState
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isDark = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Future<String?> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedImage != null) {
        if (kIsWeb) {
          return await _uploadProductImage(pickedImage);
        } else {
          return await _uploadProductImage(File(pickedImage.path));
        }
      }
      return null;
    } catch (e) {
      print('Error picking/uploading image: $e');
      return null;
    }
  }

  bool _validateProductInput(
    String name,
    String price,
    String stock,
    String? category,
    String? mainImage,
  ) {
    if (name.isEmpty ||
        price.isEmpty ||
        stock.isEmpty ||
        category == null ||
        mainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields and add a main image',
          ),
        ),
      );
      return false;
    }

    if (double.tryParse(price) == null || int.tryParse(stock) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid price and stock numbers')),
      );
      return false;
    }

    return true;
  }

  Future<void> _saveProduct(
    String name,
    double price,
    int stock,
    String category,
    String description,
    String mainImage,
    List<String> additionalImages,
  ) async {
    try {
      final product = {
        'name': name,
        'price': price,
        'stock': stock,
        'category': category,
        'description': description,
        'imagePath': mainImage,
        'images': [mainImage, ...additionalImages],
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('products').add(product);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Product added successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding product: $e')));
      }
    }
  }

  // First, add this method to search for products by name
  Future<List<Product>> _searchProducts(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final snapshot =
          await FirebaseFirestore.instance.collection('products').get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return Product(
              id: doc.id,
              name: data['name'] as String,
              price: (data['price'] as num).toDouble(),
              category: data['category'] as String,
              description: data['description'] as String? ?? '',
              imageUrl: data['imagePath'] as String? ?? '',
              images: List<String>.from(
                data['images'] ?? [],
              ), // Properly cast images array
              stock: data['stock'] as int? ?? 0,
            );
          })
          .where((product) => product.name.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // Add this method to show the product search dialog
  void _showProductSearchDialog() {
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Search Product to Update'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final products = await _searchProducts(searchController.text);
                  Navigator.pop(context);
                  if (products.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No products found')),
                    );
                  } else {
                    _showProductSelectionDialog(products);
                  }
                },
                child: Text('Search'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Add this method to show the product selection dialog
  void _showProductSelectionDialog(List<Product> products) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Product to Update'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  leading:
                      product.imageUrl.isNotEmpty
                          ? Image.network(
                            product.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                          : Icon(Icons.image_not_supported),
                  title: Text(product.name),
                  subtitle: Text('₺${product.price.toStringAsFixed(2)}'),
                  onTap: () {
                    Navigator.pop(context);
                    _showUpdateProductDialog(product);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Update this method in _AIChatScreenState class
  void _showUpdateProductDialog(Product product) {
    final TextEditingController nameController = TextEditingController(
      text: product.name,
    );
    final TextEditingController priceController = TextEditingController(
      text: product.price.toString(),
    );
    final TextEditingController stockController = TextEditingController(
      text: product.stock.toString(),
    );
    final TextEditingController descriptionController = TextEditingController(
      text: product.description,
    );
    String? selectedCategory = product.category;
    String mainImagePath = product.imageUrl;
    List<String> additionalImagePaths = List.from(product.images)..remove(
      product.imageUrl,
    ); // Remove main image since it's already shown in mainImagePath
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor =
        _selectedTheme != null ? getThemeColor(_selectedTheme!) : Colors.red;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Product',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            SizedBox(height: 20),
                            // Main Image Selection
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: themeColor.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child:
                                  mainImagePath.isNotEmpty
                                      ? Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              13,
                                            ),
                                            child: Image.network(
                                              mainImagePath,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                              ),
                                              onPressed: () async {
                                                final imageUrl =
                                                    await _pickAndUploadImage();
                                                if (imageUrl != null) {
                                                  setState(
                                                    () =>
                                                        mainImagePath =
                                                            imageUrl,
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                      : InkWell(
                                        onTap: () async {
                                          final imageUrl =
                                              await _pickAndUploadImage();
                                          if (imageUrl != null) {
                                            setState(
                                              () => mainImagePath = imageUrl,
                                            );
                                          }
                                        },
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                size: 40,
                                                color: themeColor,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Update Main Image',
                                                style: TextStyle(
                                                  color: themeColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                            ),
                            SizedBox(height: 16),
                            // Additional Images
                            Container(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: max(
                                  3,
                                  additionalImagePaths.length,
                                ), // Use max to show at least 3 slots
                                itemBuilder: (context, index) {
                                  final hasImage =
                                      index < additionalImagePaths.length;
                                  return Container(
                                    width: 100,
                                    margin: EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: themeColor.withOpacity(0.5),
                                      ),
                                    ),
                                    child:
                                        hasImage
                                            ? Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                  child: Image.network(
                                                    additionalImagePaths[index],
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Center(
                                                          child: Icon(
                                                            Icons.error,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        additionalImagePaths
                                                            .removeAt(index);
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            )
                                            : InkWell(
                                              onTap: () async {
                                                final imageUrl =
                                                    await _pickAndUploadImage();
                                                if (imageUrl != null) {
                                                  setState(() {
                                                    additionalImagePaths.add(
                                                      imageUrl,
                                                    );
                                                  });
                                                }
                                              },
                                              child: Center(
                                                child: Icon(
                                                  Icons.add_photo_alternate,
                                                  color: themeColor,
                                                ),
                                              ),
                                            ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 16),
                            // Product Details Fields
                            _buildTextField(
                              controller: nameController,
                              label: 'Product Name',
                              isDark: isDark,
                            ),
                            SizedBox(height: 12),
                            _buildTextField(
                              controller: priceController,
                              label: 'Price (TRY)',
                              keyboardType: TextInputType.number,
                              isDark: isDark,
                            ),
                            SizedBox(height: 12),
                            _buildTextField(
                              controller: stockController,
                              label: 'Stock Quantity',
                              keyboardType: TextInputType.number,
                              isDark: isDark,
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade300,
                                ),
                              ),
                              child: FutureBuilder<List<String>>(
                                future: _fetchCategories(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final categories =
                                      snapshot.data ??
                                      [
                                        "CPU's",
                                        "GPU's",
                                        "RAM's",
                                        "Storage",
                                        "Motherboards",
                                        "Cases",
                                        "PSUs",
                                      ];

                                  // Check if selectedCategory exists in the categories list
                                  if (selectedCategory != null &&
                                      !categories.contains(selectedCategory)) {
                                    // If category doesn't exist anymore, reset selection to null
                                    selectedCategory = null;
                                  }

                                  return DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedCategory,
                                      isExpanded: true,
                                      hint: Text('Select Category'),
                                      items:
                                          categories.map((String category) {
                                            return DropdownMenuItem(
                                              value: category,
                                              child: Text(category),
                                            );
                                          }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(
                                          () => selectedCategory = newValue,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildTextField(
                              controller: descriptionController,
                              label: 'Description',
                              maxLines: 3,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              try {
                                final updatedProduct = {
                                  'name': nameController.text,
                                  'price': double.parse(priceController.text),
                                  'stock': int.parse(stockController.text),
                                  'category': selectedCategory,
                                  'description': descriptionController.text,
                                  'imagePath': mainImagePath,
                                  'images': [
                                    mainImagePath,
                                    ...additionalImagePaths,
                                  ],
                                  'updatedAt': FieldValue.serverTimestamp(),
                                };

                                await FirebaseFirestore.instance
                                    .collection('products')
                                    .doc(product.id)
                                    .update(updatedProduct);

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Product updated successfully',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating product: $e'),
                                  ),
                                );
                              }
                            },
                            child: Text('Update Product'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Update the _uploadProductImage method to handle image URL returns
  Widget _buildImageUploadField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor =
        _selectedTheme != null ? getThemeColor(_selectedTheme!) : Colors.red;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Ask Me Anything...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade800 : Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? themeColor.shade900 : themeColor.shade700,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    if (_messageController.text.trim().isNotEmpty) {
                      _handleSubmitted(_messageController.text);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this method to handle image messages
  void _handleImageMessage(String? imageUrl) {
    if (imageUrl != null) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Image uploaded: $imageUrl\n${_messageController.text}',
            isUser: true,
          ),
        );
        _messageController.clear();
      });
    }
  }

  // Add this method to _AIChatScreenState class
  Future<List<String>> _fetchCategories() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('categories')
              .orderBy('name')
              .get();

      return snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      // Return default categories as fallback
      return [
        "CPU's",
        "GPU's",
        "RAM's",
        "Storage",
        "Motherboards",
        "Cases",
        "PSUs",
      ];
    }
  }

  // Add this method to _AIChatScreenState class
  void _showManageCategoriesDialog() {
    final TextEditingController categoryController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor =
        _selectedTheme != null ? getThemeColor(_selectedTheme!) : Colors.red;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Manage Categories'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: categoryController,
                        decoration: InputDecoration(
                          labelText: 'New Category',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () async {
                        if (categoryController.text.trim().isNotEmpty) {
                          await FirebaseFirestore.instance
                              .collection('categories')
                              .add({
                                'name': categoryController.text.trim(),
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                          categoryController.clear();
                          setState(() {}); // Refresh the dialog
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('categories')
                          .orderBy('name')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final category = snapshot.data!.docs[index];
                          return ListTile(
                            title: Text(category['name']),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                try {
                                  final categoryName = category['name'];
                                  final isInUse = await _isCategoryInUse(
                                    categoryName,
                                  );

                                  if (isInUse) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Cannot delete category "$categoryName" because it is being used by existing products',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  // Show confirmation dialog
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Confirm Deletion'),
                                        content: Text(
                                          'Are you sure you want to delete the category "$categoryName"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirmed == true) {
                                    await FirebaseFirestore.instance
                                        .collection('categories')
                                        .doc(category.id)
                                        .delete();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Category "$categoryName" deleted successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error deleting category: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Add this helper method to check if category is in use
  Future<bool> _isCategoryInUse(String categoryName) async {
    final productsSnapshot =
        await FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: categoryName)
            .get();

    return productsSnapshot.docs.isNotEmpty;
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final List<Product>? recommendedProducts;
  final String? imageUrl;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.recommendedProducts,
    this.imageUrl,
  });
}

class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String description;
  final String imageUrl;
  final List<String> images;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.images = const [],
    required this.stock, // Make sure stock is required
  });
}
