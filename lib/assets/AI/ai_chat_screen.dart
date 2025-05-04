import 'package:engineering_project/assets/AI/api_config.dart';
import 'package:engineering_project/assets/components/cart_manager.dart';
import 'package:engineering_project/models/product.dart';
import 'package:engineering_project/pages/cart_page.dart';
import 'package:engineering_project/screens/cart_screen.dart';
import 'package:engineering_project/pages/product-detail-page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:engineering_project/providers/cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with SingleTickerProviderStateMixin {
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
  ];

  final String systemPrompt = '''
  You are a knowledgeable PC hardware assistant. Help users with PC builds and hardware recommendations.
  Keep responses concise and focus on suggesting compatible hardware components.
  When asked about PC builds, consider the user's budget and intended use (gaming, work, etc.).
  ''';

  // Add these variables at the top with other declarations
  final List<String> _apiKeys = [
    APIConfig.ApiKey,
    APIConfig.ApiKey2,
    APIConfig.ApiKey3,
    APIConfig.ApiKey4,
  ];
  int _currentApiKeyIndex = 0;

  // Add this method to get next API key
  String _getNextApiKey() {
    _currentApiKeyIndex = (_currentApiKeyIndex + 1) % _apiKeys.length;
    return _apiKeys[_currentApiKeyIndex];
  }

  // OpenRouter Configuration
  static const String _openRouterApiKey = APIConfig.ApiKey4; // Replace with your key
  static const String _openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FirebaseFirestore.instance
        .collection('settings')
        .doc('ai_settings')
        .snapshots()
        .listen((doc) {
      if (mounted) {
        setState(() {
          _isAIEnabled = doc.exists ? (doc.data()?['isEnabled'] ?? true) : true;
        });
      }
    });
  }

  @override
  void dispose() {
    _typingAnimation?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userData = await FirebaseFirestore.instance
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
      final doc = await FirebaseFirestore.instance
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Tommy'),
        backgroundColor: isDark ? Colors.black : Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.grey[50],
              ),
              child: _messages.isEmpty
                  ? _buildConversationStarters() // Show starters when no messages
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        final message = _messages[_messages.length - 1 - index];
                        return _buildMessage(message);
                      },
                    ),
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
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
                          hintText: 'Ask me anything...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade800 : Colors.grey[100],
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        onSubmitted: _handleSubmitted,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.red.shade900 : Colors.red.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
                        onPressed: () => _handleSubmitted(_messageController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationStarters() {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(24),
        margin: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: _conversationStarters.map((starter) {
                return ElevatedButton(
                  onPressed: () {
                    if (starter == 'I need assistance') {
                      _launchWhatsApp();
                    } else {
                      _messageController.text = starter;
                      _handleSubmitted(starter);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isDark ? Colors.red.shade900 : Colors.red.shade100,
            child: Image.asset(
              'lib/assets/Images/Mascot/mascot-default.png',
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildDot(1),
                _buildDot(2),
                _buildDot(3),
              ],
            ),
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
        double opacity = sin((_typingAnimation!.value * pi * 2) - (index * pi / 2));
        opacity = opacity.clamp(0.3, 1.0);
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.red.shade400)
              .withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) 
                CircleAvatar(
                  backgroundColor: isDark ? Colors.red.shade900 : Colors.red.shade100,
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
                    color: message.isUser 
                      ? (isDark ? Colors.red.shade900 : Colors.red.shade400)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(message.isUser ? 20 : 0),
                      topRight: Radius.circular(message.isUser ? 0 : 20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser 
                        ? Colors.white 
                        : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (message.isUser)
                CircleAvatar(
                  backgroundColor: isDark ? Colors.red.shade900 : Colors.red.shade100,
                  backgroundImage: _userProfileImage != null 
                    ? NetworkImage(_userProfileImage!) 
                    : null,
                  child: _userProfileImage == null ? Icon(
                    Icons.person,
                    color: isDark ? Colors.white70 : Colors.red.shade400,
                  ) : null,
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
                            builder: (context) => ProductDetailPage(
                              productId: product.id,
                            ),
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
                              '\$${product.price.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.green),
                            ),
                            TextButton(
                              onPressed: () => _addToCart(product),
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
          if (!message.isUser && message.recommendedProducts != null && message.recommendedProducts!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton.icon(
                onPressed: () => _showAddToCartDialog(message.recommendedProducts!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: Icon(Icons.shopping_cart),
                label: Text('Add All Recommended Products to Cart'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _messageController.clear();
      _isTyping = true;
    });

    try {
      final (response, recommendations) = await _getAIResponse(text);
      print('Got ${recommendations.length} recommendations'); // Debug print
      
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            recommendedProducts: recommendations.isNotEmpty ? recommendations : null,
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get response. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error in _handleSubmitted: $e');
    }
  }

  Future<(String, List<Product>)> _getAIResponse(String message) async {
    if (!_isAIEnabled) {
      return Future.value(('I\'m currently on vacation!! Try to talk to me later :P', <Product>[]));
    }

    for (int attempt = 0; attempt < _apiKeys.length; attempt++) {
      try {
        final List<Product> recommendations = await _getProductRecommendations(message);
        
        final response = await http.post(
          Uri.parse(_openRouterUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_apiKeys[_currentApiKeyIndex]}',
            'HTTP-Referer': 'https://your-app-domain.com',
            'X-Title': 'Your App Name',
          },
          body: jsonEncode({
            'model': 'openai/gpt-3.5-turbo',
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': message}
            ],
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          String aiResponse = data['choices'][0]['message']['content'] as String;
          return (aiResponse, recommendations);
        } else if (response.statusCode == 401) {
          print('API key ${_currentApiKeyIndex + 1} failed, trying next key...');
          _getNextApiKey();
          if (attempt == _apiKeys.length - 1) {
            return (APIConfig.fallbackResponses[Random().nextInt(APIConfig.fallbackResponses.length)], <Product>[]);
          }
          continue;
        } else {
          throw Exception('Error ${response.statusCode}');
        }
      } catch (e) {
        print('Error with API key ${_currentApiKeyIndex + 1}: $e');
        if (attempt == _apiKeys.length - 1) {
          return (APIConfig.fallbackResponses[Random().nextInt(APIConfig.fallbackResponses.length)], <Product>[]);
        }
        _getNextApiKey();
      }
    }
    return ('I apologize, but I\'m currently unavailable. Please try again later.', <Product>[]);
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CartPage(),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $e')),
      );
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
                  MaterialPageRoute(
                    builder: (context) => const CartPage(),
                  ),
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

  Future<List<Product>> _getProductRecommendations(String message) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final List<Product> recommendations = [];
      final lowercaseMessage = message.toLowerCase();
      
      // Define preferences based on message
      final bool preferIntel = lowercaseMessage.contains('intel');
      final bool preferAMD = lowercaseMessage.contains('amd') || lowercaseMessage.contains('ryzen');
      final bool isGaming = lowercaseMessage.contains('gaming') || lowercaseMessage.contains('game');
      
      // Get all products first
      final QuerySnapshot allProducts = await firestore.collection('products').get();
      
      // Group products by category
      Map<String, List<DocumentSnapshot>> productsByCategory = {};
      for (var doc in allProducts.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String;
        productsByCategory.putIfAbsent(category, () => []).add(doc);
      }

      // Process CPU category first with preference
      if (productsByCategory.containsKey('CPU\'s')) {
        var cpus = productsByCategory['CPU\'s']!;
        DocumentSnapshot? selectedCPU;
        
        if (preferIntel) {
          selectedCPU = cpus.firstWhere(
            (doc) => (doc.data() as Map<String, dynamic>)['name'].toString().toLowerCase().contains('intel'),
            orElse: () => cpus.first
          );
        } else if (preferAMD) {
          selectedCPU = cpus.firstWhere(
            (doc) => (doc.data() as Map<String, dynamic>)['name'].toString().toLowerCase().contains('amd'),
            orElse: () => cpus.first
          );
        } else {
          selectedCPU = cpus.first;
        }

        final cpuData = selectedCPU.data() as Map<String, dynamic>;
        recommendations.add(Product(
          id: selectedCPU.id,
          name: cpuData['name'] ?? '',
          category: cpuData['category'] ?? '',
          price: (cpuData['price'] is int) 
              ? (cpuData['price'] as int).toDouble() 
              : (cpuData['price'] ?? 0).toDouble(),
          description: cpuData['description'] ?? '',
          imageUrl: cpuData['imagePath'] ?? '',
        ));
      }

      // Process other categories
      final categoriesToProcess = ['Motherboards', 'RAM\'s', 'GPU\'s', 'Storage', 'PSU', 'Case'];
      
      for (final category in categoriesToProcess) {
        if (productsByCategory.containsKey(category)) {
          var products = productsByCategory[category]!;
          if (products.isNotEmpty) {
            // Sort by rating if available
            products.sort((a, b) {
              final ratingA = (a.data() as Map<String, dynamic>)['averageRating'] ?? 0.0;
              final ratingB = (b.data() as Map<String, dynamic>)['averageRating'] ?? 0.0;
              return (ratingB as num).compareTo(ratingA as num);
            });

            final doc = products.first;
            final data = doc.data() as Map<String, dynamic>;
            recommendations.add(Product(
              id: doc.id,
              name: data['name'] ?? '',
              category: data['category'] ?? '',
              price: (data['price'] is int) 
                  ? (data['price'] as int).toDouble() 
                  : (data['price'] ?? 0).toDouble(),
              description: data['description'] ?? '',
              imageUrl: data['imagePath'] ?? '',
            ));
          } else {
            recommendations.add(Product(
              id: 'empty_${category.toLowerCase()}',
              name: 'No Available Product',
              category: category,
              price: 0,
              description: 'There is not any available product in this category',
              imageUrl: '',
            ));
          }
        }
      }

      print('Final recommendations count: ${recommendations.length}');
      recommendations.forEach((product) {
        print('Recommending: ${product.name} (${product.category})');
      });

      return recommendations;
    } catch (e) {
      print('Error fetching products from Firestore: $e');
      return [];
    }
  }

  Future<void> _testFirebaseConnection() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final QuerySnapshot snapshot = await firestore.collection('products').limit(1).get();
      print('Firebase connection test: ${snapshot.docs.length} documents found');
      if (snapshot.docs.isNotEmpty) {
        print('Sample document data: ${snapshot.docs.first.data()}');
      }
    } catch (e) {
      print('Firebase connection test failed: $e');
    }
  }

  // Add this method to show the confirmation dialog
  void _showAddToCartDialog(List<Product> products) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey.shade900 
              : Colors.white,
          title: Text(
            'Add to Cart',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black87,
            ),
          ),
          content: Text(
            'Do you want to add all recommended products to your cart?',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white70 
                  : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'No',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white70 
                      : Colors.grey.shade700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addAllToCart(products);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final List<Product>? recommendedProducts;

  ChatMessage({
    required this.text, 
    required this.isUser, 
    this.recommendedProducts,
  });
}