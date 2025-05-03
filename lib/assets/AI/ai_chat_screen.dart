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

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  DateTime? _lastRequestTime;

  // OpenRouter Configuration
  static const String _openRouterApiKey = APIConfig.openAIApiKey; // Replace with your key
  static const String _openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              reverse: true,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return _buildMessage(message);
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 8),
                  Text("AI is thinking..."),
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message bubble
          Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!message.isUser) const CircleAvatar(child: Icon(Icons.smart_toy)),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (message.isUser) const CircleAvatar(child: Icon(Icons.person)),
            ],
          ),
          
          // Only show recommendations and prompt for AI messages
          if (!message.isUser && message.recommendedProducts != null && message.recommendedProducts!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Recommended Components:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 320,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: message.recommendedProducts!.length,
                    itemBuilder: (context, index) {
                      final product = message.recommendedProducts![index];
                      return GestureDetector(
                        onTap: () {
                          if (!product.id.startsWith('empty_')) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProductDetailPage(
                                  productId: product.id,
                                ),
                              ),
                            );
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          elevation: 4,
                          child: Container(
                            width: 220,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.id.startsWith('empty_'))
                                  // Show placeholder for empty category
                                  Container(
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey[400]),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Not Available',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  // Show normal product image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => ProductDetailPage(
                                              productId: product.id,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Hero(
                                        tag: 'product_${product.id}',
                                        child: Image.network(
                                          product.imageUrl,
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                                height: 120,
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.error),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product.category,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: product.id.startsWith('empty_') ? Colors.grey : Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                if (!product.id.startsWith('empty_'))
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$${product.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _addToCart(product),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                                          label: const Text('Add to Cart'),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Do you want me to add the recommended build to your cart?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _addAllToCart(message.recommendedProducts!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Yes, add all'),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {}, // Do nothing on no
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('No, thanks'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              onSubmitted: _handleSubmitted,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _handleSubmitted(_messageController.text),
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
    try {
      final List<Product> recommendations = await _getProductRecommendations(message);
      
      final systemPrompt = '''You are a computer hardware expert helping customers choose PC components.
      For each recommended component, provide TWO specific sentences:
      1. First sentence should explain the key features and specifications
      2. Second sentence should explain why it's a good choice for the user's needs
      
      FORMAT YOUR RESPONSE LIKE THIS:
      Here's a recommended build based on your requirements:

      CPU: [Product Name]
      - [Feature sentence about specs and capabilities]
      - [Benefits sentence explaining why it fits user's needs]

      Motherboard: [Product Name]
      - [Feature sentence about specs and capabilities]
      - [Benefits sentence explaining why it fits user's needs]

      RAM: [Product Name]
      - [Feature sentence about specs and capabilities]
      - [Benefits sentence explaining why it fits user's needs]

      GPU: [Product Name]
      - [Feature sentence about specs and capabilities]
      - [Benefits sentence explaining why it fits user's needs]

      Storage: [Product Name]
      - [Feature sentence about specs and capabilities]
      - [Benefits sentence explaining why it fits user's needs]

      Power Supply: [Product Name]
      - [Feature sentence about specs and capabilities]
      - [Benefits sentence explaining why it fits user's needs]

      Case: [Product Name]
      - [Feature sentence about specs and capabilities]
      - [Benefits sentence explaining why it fits user's needs]

      Summary: These components work well together because: [Brief compatibility explanation]
      ''';

      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openRouterApiKey',
          'HTTP-Referer': 'https://your-app-domain.com',
          'X-Title': 'Your App Name',
        },
        body: jsonEncode({
          'model': 'openai/gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': message,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['choices'][0]['message']['content'] as String;
        
        // Only return recommendations if we have both AI response and products
        if (recommendations.isEmpty) {
          return ('I apologize, but I couldn\'t find any product recommendations matching your request.', <Product>[]);
        }
        
        return (aiResponse, recommendations);
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in _getAIResponse: $e');
      return ('I apologize, but I encountered an error while processing your request.', <Product>[]);
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