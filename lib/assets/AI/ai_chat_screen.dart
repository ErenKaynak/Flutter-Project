import 'dart:io';

import 'package:engineering_project/assets/AI/local_ai_config.dart';
import 'package:engineering_project/assets/AI/local_ai_service.dart';
import 'package:engineering_project/assets/AI/imgur_config.dart';
import 'package:engineering_project/assets/components/cart_manager.dart';
import 'package:engineering_project/models/product.dart';
import 'package:engineering_project/pages/cart_page.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
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
import 'package:firebase_storage/firebase_storage.dart';
import 'package:engineering_project/l10n/app_localizations.dart';

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
  bool _isLocalAIAvailable = false;
  String? _userProfileImage;
  bool _isAdmin = false;
  String? _currentProductId;
  SpecialColorTheme? _selectedTheme;

  AnimationController? _typingAnimation;

  final List<String> _conversationStarters = [
    'iNeedAssistance',
    'recommendCheapestPC',
    'lookingForGamingPC',
    'addNewProduct',
    'updateProduct',
  ];

  /*final String systemPrompt = '''
You are a knowledgeable assistant who can help with PC hardware and other topics.
- Respond naturally to user queries
- Keep responses concise but helpful
- Adapt your tone to match the user's style
''';*/

  @override
  void initState() {
    super.initState();
    _typingAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    _checkLocalAIAvailability();
    _loadUserProfile();
    _checkAdminStatus();
  }

  Future<void> _checkLocalAIAvailability() async {
    final isAvailable = await LocalAIService.isAvailable();
    setState(() {
      _isLocalAIAvailable = isAvailable;
    });

    if (!isAvailable) {
      _showLocalAIError();
    }
  }

  void _showLocalAIError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Local AI is not available. Please make sure LM Studio is running.'),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _checkLocalAIAvailability,
          ),
        ),
      );
    }
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
      // Check if the message is asking for PC recommendations
      if (text.toLowerCase().contains('recommend') || 
          text.toLowerCase().contains('suggestion') ||
          text.toLowerCase().contains('build')) {
        
        // Extract preferences from the message
        Map<String, String> preferences = {
          'use_case': text.toLowerCase().contains('gaming') ? 'gaming' : 'general',
          'cpu_brand': text.toLowerCase().contains('intel') ? 'intel' : 
                      text.toLowerCase().contains('amd') ? 'amd' : '',
        };

        // Get product recommendations
        final recommendations = await _getProductRecommendations(text, preferences);
        
        if (recommendations.isNotEmpty) {
          // Create a message with the recommendations
          String recommendationText = 'Here are my recommendations for your PC build:\n\n';
          for (var product in recommendations) {
            recommendationText += '• ${product.name}\n';
          }
          recommendationText += '\nWould you like to know more about any of these components? I can provide detailed information about:\n';
          recommendationText += '- Technical specifications\n';
          recommendationText += '- Performance characteristics\n';
          recommendationText += '- Compatibility information\n';
          recommendationText += '- Best use cases\n';
          recommendationText += '- Price-to-performance ratio\n';
          recommendationText += '- User reviews and ratings';

          // Add the message with recommendations
          _addMessage(ChatMessage(
            text: recommendationText,
            isUser: false,
            recommendedProducts: recommendations,
          ));
        } else {
          _addMessage(ChatMessage(
            text: 'I couldn\'t find suitable components for your build. Could you please provide more details about your requirements?',
            isUser: false,
          ));
        }
      } else if (_messages.isNotEmpty && 
                 _messages.last.recommendedProducts != null &&
                 _messages.last.recommendedProducts!.isNotEmpty) {
        // Check if user is asking about a recommended product
        final lastRecommendations = _messages.last.recommendedProducts!;
        Product? askedProduct;
        
        for (var product in lastRecommendations) {
          if (text.toLowerCase().contains(product.name.toLowerCase())) {
            askedProduct = product;
            break;
          }
        }

        if (askedProduct != null) {
          // Get detailed information about the product from AI
          final response = await LocalAIService.getChatCompletion(
            'Provide detailed information about this PC component: ${askedProduct.name}. Include:\n' +
            '1. Technical Specifications:\n' +
            '   - Detailed hardware specifications\n' +
            '   - Performance metrics\n' +
            '   - Power requirements\n' +
            '2. Performance Analysis:\n' +
            '   - Gaming performance\n' +
            '   - Productivity performance\n' +
            '   - Benchmark comparisons\n' +
            '3. Compatibility:\n' +
            '   - System requirements\n' +
            '   - Compatible components\n' +
            '   - Potential bottlenecks\n' +
            '4. Use Cases:\n' +
            '   - Ideal scenarios\n' +
            '   - Target users\n' +
            '   - Value proposition\n' +
            '5. Price Analysis:\n' +
            '   - Price-to-performance ratio\n' +
            '   - Market positioning\n' +
            '   - Value for money\n' +
            '6. User Experience:\n' +
            '   - Common user feedback\n' +
            '   - Pros and cons\n' +
            '   - Reliability and durability',
            'You are a PC hardware expert with deep knowledge of computer components. Provide detailed, accurate, and comprehensive information about PC hardware. Focus on technical accuracy, practical implications, and real-world performance. Use a professional but accessible tone. Include specific numbers and metrics when available.'
          );

          _addMessage(ChatMessage(
            text: response,
            isUser: false,
            recommendedProducts: [askedProduct],
          ));
        } else {
          // Regular chat response
          final response = await LocalAIService.getChatCompletion(
            text,
            'You are a knowledgeable PC hardware assistant. Provide detailed, accurate information about computer components and PC building. Include specific technical details, performance metrics, and practical advice. Use a professional but accessible tone.'
          );

          _addMessage(ChatMessage(
            text: response,
            isUser: false,
          ));
        }
      } else {
        // Regular chat response
        final response = await LocalAIService.getChatCompletion(
          text,
          'You are a knowledgeable PC hardware assistant. Provide detailed, accurate information about computer components and PC building. Include specific technical details, performance metrics, and practical advice. Use a professional but accessible tone.'
        );

        _addMessage(ChatMessage(
          text: response,
          isUser: false,
        ));
      }
    } catch (e) {
      print('Error in chat response: $e');
      _addMessage(ChatMessage(
        text: 'Sorry, I encountered an error. Please try again.',
        isUser: false,
      ));
    }
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
              _isLocalAIAvailable =
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
    _debugAdminStatus();
    final l10n = AppLocalizations.of(context)!;

    // Get the theme notifier using Consumer instead of Provider.of
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        final isDark = themeNotifier.isDarkMode;
        final themeColor = themeNotifier.isSpecialModeActive 
            ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
            : Colors.red;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.aiChatTitle),
            backgroundColor: isDark 
                ? Colors.black
                : themeColor,
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
                            itemBuilder: (context, index) {
                              return _buildMessage(_messages[index]);
                            },
                          ),
                ),
              ),
              if (_isTyping) _buildTypingIndicator(),
              _buildImageUploadField(), // Add this line
            ],
          ),
        );
      },
    );
  }

  Widget _buildConversationStarters() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.all(24),
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800.withOpacity(0.7) : Colors.white.withOpacity(0.9),
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
                l10n.howCanIHelp,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: _getFilteredStarters().map((starter) {
                  String localizedText = '';
                  switch (starter) {
                    case 'iNeedAssistance':
                      localizedText = l10n.iNeedAssistance;
                      break;
                    case 'recommendCheapestPC':
                      localizedText = l10n.recommendCheapestPC;
                      break;
                    case 'lookingForGamingPC':
                      localizedText = l10n.lookingForGamingPC;
                      break;
                    case 'addNewProduct':
                      localizedText = l10n.addNewProduct;
                      break;
                    case 'updateProduct':
                      localizedText = l10n.updateProduct;
                      break;
                  }
                  return SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () {
                        if (starter == 'addNewProduct') {
                          _showAddProductDialog();
                        } else if (starter == 'iNeedAssistance') {
                          _launchWhatsApp();
                        } else if (starter == 'updateProduct') {
                          _showProductSearchDialog();
                        } else {
                          _messageController.text = localizedText;
                          _handleSubmitted(localizedText);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? themeColor.shade700 : themeColor.shade400,
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
                        localizedText,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

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
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    // Clean up any code formatting from the response
    String cleanText = message.text.replaceAll(RegExp(r'```[\w]*\n|```'), '')
                                  .replaceAll(RegExp(r'\*[\w]*\n'), '')
                                  .trim();
  
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                CircleAvatar(
                  backgroundColor: isDark ? themeColor.shade900 : themeColor.shade100,
                  child: Image.asset(
                    'lib/assets/Images/Mascot/mascot-crossedarms.png',
                    width: 37,
                    height: 37,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: message.isUser 
                      ? (isDark ? themeColor.shade900 : themeColor.shade400)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
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
                      Text(
                        cleanText,
                        style: TextStyle(
                          color: message.isUser 
                            ? Colors.white 
                            : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      if (message.recommendedProducts != null && message.recommendedProducts!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddToCartDialog(message.recommendedProducts!),
                            icon: Icon(Icons.shopping_cart, color: Colors.white),
                            label: Text('Add All to Cart'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: isDark ? themeColor.shade900 : themeColor.shade100,
                  backgroundImage: _userProfileImage != null ? NetworkImage(_userProfileImage!) : null,
                  child: _userProfileImage == null 
                    ? Icon(Icons.person, color: isDark ? Colors.white70 : themeColor.shade400)
                    : null,
                ),
              ],
            ],
          ),
          // Add recommendation cards if available
          if (message.recommendedProducts != null && message.recommendedProducts!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: message.recommendedProducts!.map((product) => 
                  _buildRecommendationCard(product)
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Product product) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: isDark ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        product.category,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '₺${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _addToCart(product),
                  icon: Icon(Icons.shopping_cart, color: themeColor),
                  label: Text(
                    'Add to Cart',
                    style: TextStyle(color: themeColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToCartDialog(List<Product> products) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
          title: Text(
            l10n.addToCart,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Do you want to add all recommended products to your cart?',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Selected Products:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: products.map((product) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, 
                            color: themeColor,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              product.name,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            '₺${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : themeColor.shade700,
              ),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addAllToCart(products);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? themeColor.shade900 : themeColor.shade400,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.addToCart),
            ),
          ],
        );
      },
    );
  }

  void _addToCart(Product product) async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSignIn)),
      );
      return;
    }

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(product.id);

      final cartDoc = await cartRef.get();
      if (cartDoc.exists) {
        final currentQuantity = cartDoc.data()?['quantity'] ?? 1;
        final newQuantity = (currentQuantity + 1).clamp(1, 10);
        await cartRef.update({'quantity': newQuantity});
      } else {
        await cartRef.set({
          'name': product.name,
          'price': product.price.toString(),
          'imagePath': product.imageUrl,
          'quantity': 1,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.addedToCart(product.name)),
            action: SnackBarAction(
              label: l10n.viewCart,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CartPage()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorAddingToCart)),
        );
      }
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
      for (final product in products) {
        if (!product.id.startsWith('empty_')) {
          final cartRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .doc(product.id);

          final cartDoc = await cartRef.get();
          if (cartDoc.exists) {
            final currentQuantity = cartDoc.data()?['quantity'] ?? 1;
            final newQuantity = (currentQuantity + 1).clamp(1, 10);
            await cartRef.update({'quantity': newQuantity});
          } else {
            await cartRef.set({
              'name': product.name,
              'price': product.price.toString(),
              'imagePath': product.imageUrl,
              'quantity': 1,
            });
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All recommended products added to cart'),
            action: SnackBarAction(
              label: 'VIEW CART',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CartPage()),
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

  Future<void> _generateAIDescription(TextEditingController descriptionController, String productName) async {
    final l10n = AppLocalizations.of(context)!;
    
    if (productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterProductName)),
      );
      return;
    }

    try {
      final response = await LocalAIService.getChatCompletion(
        'Generate a product description for: $productName',
        'You are a professional product description writer. Create a concise, informative description for computer hardware products. Focus on key features and benefits. Keep it under 200 characters.'
      );
      
      descriptionController.text = response.trim();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneratingDescription(e.toString()))),
      );
    }
  }

  Future<List<Product>> _searchProducts(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final snapshot = await FirebaseFirestore.instance.collection('products').get();

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
              images: List<String>.from(data['images'] ?? []),
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

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
      _isTyping = false;
    });
  }

  Future<void> _checkAdminStatus() async {
    print('Checking admin status...'); // Debug print
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in'); // Debug print
        setState(() => _isAdmin = false);
        return;
      }

      print('Current user ID: ${user.uid}'); // Debug print

      // Get the user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      print('User document data: ${userDoc.data()}'); // Debug print

      if (mounted) {
        setState(() {
          // Check if the role is admin
          _isAdmin = userDoc.exists && userDoc.data()?['role'] == 'admin';
          print('Setting admin status to: $_isAdmin'); // Debug print
        });
      }

      // Set up real-time listener for role changes
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (mounted) {
          setState(() {
            _isAdmin = doc.exists && doc.data()?['role'] == 'admin';
            print('Admin status updated from listener: $_isAdmin'); // Debug print
          });
        }
      });
    } catch (e) {
      print('Error checking admin status: $e');
      if (mounted) {
        setState(() => _isAdmin = false);
      }
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

  Future<List<Product>> _getProductRecommendations(
    String message,
    Map<String, String> preferences,
  ) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final List<Product> recommendations = [];

      print('Starting product recommendations search with preferences: $preferences');

      // Get all products and filter by availability
      final QuerySnapshot allProducts = await firestore
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
          cpus = cpus.where((doc) {
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
              stock: data['stock'] as int? ?? 0,
            ),
          );
        }
      }

      // Only proceed with other components if we found a CPU
      if (recommendations.isEmpty) {
        print('No CPU found, returning empty recommendations');
        return [];
      }

      // Get CPU brand for compatibility
      final cpuBrand = recommendations.first.name.toLowerCase().contains('intel')
          ? 'intel'
          : 'amd';

      // Compatible Motherboard Selection
      if (productsByCategory.containsKey('Motherboards')) {
        var motherboards = productsByCategory['Motherboards']!.where((doc) {
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
              stock: data['stock'] as int? ?? 0,
            ),
          );
        }
      }

      // Add other components based on use case
      final isGaming = preferences['use_case'] == 'gaming';
      final isBudget = message.toLowerCase().contains('budget') ||
          message.toLowerCase().contains('cheap');

      // Define required categories
      final requiredCategories = ['RAM\'s', 'Storage', 'PSU', 'Case'];
      if (isGaming) requiredCategories.insert(1, 'GPU\'s');

      for (final category in requiredCategories) {
        if (!productsByCategory.containsKey(category)) {
          print('Category not found: $category');
          continue;
        }

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
          products = products.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final price = (data['price'] as num).toDouble();
            final name = (data['name'] as String).toLowerCase();
            // Check for gaming GPUs (RTX series or high-end AMD)
            return price >= 300 && (name.contains('rtx') || name.contains('rx'));
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
              stock: data['stock'] as int? ?? 0,
            ),
          );
        } else {
          print('No products found for category: $category');
        }
      }

      print('Final recommendations: ${recommendations.length} products');
      return recommendations;
    } catch (e) {
      print('Error in _getProductRecommendations: $e');
      return [];
    }
  }

  Widget _buildImageUploadField() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;
    final l10n = AppLocalizations.of(context)!;

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
                    hintText: l10n.askMeAnything,
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

  void _showAddProductDialog() {
    final l10n = AppLocalizations.of(context)!;

    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminOnly)),
      );
      return;
    }

    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController stockController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String? selectedCategory;
    String? mainImagePath;
    List<String> additionalImagePaths = [];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
            final isDark = themeNotifier.isDarkMode;
            final themeColor = themeNotifier.isSpecialModeActive 
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                : Colors.red;
            final l10n = AppLocalizations.of(context)!;

            return Dialog(
              backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.addNewProduct,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: nameController,
                        label: l10n.productName,
                        isDark: isDark,
                        prefixIcon: Icons.inventory_2,
                      ),
                      SizedBox(height: 12),
                      _buildTextField(
                        controller: priceController,
                        label: l10n.price,
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.attach_money,
                      ),
                      SizedBox(height: 12),
                      _buildTextField(
                        controller: stockController,
                        label: l10n.stock,
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.warehouse,
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.category,
                              color: isDark ? themeColor.shade200 : themeColor,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: FutureBuilder<List<String>>(
                                future: _fetchCategories(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return CircularProgressIndicator();
                                  }
                                  return DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedCategory,
                                      hint: Text(
                                        l10n.selectCategory,
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                      isExpanded: true,
                                      dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
                                      items: snapshot.data!.map((String category) {
                                        return DropdownMenuItem<String>(
                                          value: category,
                                          child: Text(
                                            category,
                                            style: TextStyle(
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedCategory = newValue;
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildTextField(
                        controller: descriptionController,
                        label: l10n.productDescription,
                        isDark: isDark,
                        maxLines: 3,
                        prefixIcon: Icons.description,
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.auto_fix_high,
                            color: isDark ? themeColor.shade200 : themeColor,
                          ),
                          onPressed: () async {
                            if (nameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a product name first')),
                              );
                              return;
                            }

                            await _generateAIDescription(descriptionController, nameController.text);
                          },
                          tooltip: l10n.generateAIDescription,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.mainImage,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: themeColor.withOpacity(0.5),
                                ),
                              ),
                              child: mainImagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: Image.network(
                                        mainImagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Center(
                                          child: Icon(
                                            Icons.error,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        Icons.add_photo_alternate,
                                        color: themeColor,
                                        size: 32,
                                      ),
                                      onPressed: () async {
                                        final imageUrl = await _pickAndUploadImage();
                                        if (imageUrl != null) {
                                          setState(() {
                                            mainImagePath = imageUrl;
                                          });
                                        }
                                      },
                                    ),
                            ),
                            if (mainImagePath != null)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      mainImagePath = null;
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.additionalImages,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: List.generate(3, (index) {
                              final hasImage = index < additionalImagePaths.length;
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: themeColor.withOpacity(0.5),
                                        ),
                                      ),
                                      child: hasImage
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(9),
                                              child: Image.network(
                                                additionalImagePaths[index],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Center(
                                                  child: Icon(
                                                    Icons.error,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : IconButton(
                                              icon: Icon(
                                                Icons.add_photo_alternate,
                                                color: themeColor,
                                                size: 32,
                                              ),
                                              onPressed: () async {
                                                final imageUrl = await _pickAndUploadImage();
                                                if (imageUrl != null) {
                                                  setState(() {
                                                    if (index >= additionalImagePaths.length) {
                                                      additionalImagePaths.add(imageUrl);
                                                    } else {
                                                      additionalImagePaths[index] = imageUrl;
                                                    }
                                                  });
                                                }
                                              },
                                            ),
                                    ),
                                    if (hasImage)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              additionalImagePaths.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              if (_validateProductInput(
                                nameController.text,
                                priceController.text,
                                stockController.text,
                                selectedCategory,
                                mainImagePath,
                              )) {
                                try {
                                  if (mainImagePath?.isEmpty ?? true) {
                                    throw Exception('Please upload a main image');
                                  }

                                  final updatedProduct = {
                                    'name': nameController.text,
                                    'price': double.parse(priceController.text),
                                    'stock': int.parse(stockController.text),
                                    'category': selectedCategory,
                                    'description': descriptionController.text,
                                    'imagePath': mainImagePath!,
                                    'images': [mainImagePath, ...additionalImagePaths],
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  };

                                  await FirebaseFirestore.instance
                                      .collection('products')
                                      .doc(_currentProductId)
                                      .update(updatedProduct);

                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Product updated successfully')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error updating product: $e')),
                                  );
                                }
                              }
                            },
                            child: Text(l10n.update),
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

  void _showProductSearchDialog() {
    final TextEditingController searchController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.searchProduct),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: l10n.productName,
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
                      SnackBar(content: Text(l10n.noProductsFound)),
                    );
                  } else {
                    _showProductSelectionDialog(products);
                  }
                },
                child: Text(l10n.searchProducts),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    TextInputType? keyboardType,
    int? maxLines,
    IconData? prefixIcon,
    Widget? suffixIcon,
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
        maxLines: maxLines ?? 1,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: isDark ? Colors.white70 : Colors.black87,
                )
              : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Future<List<String>> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('categories').get();
      return snapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<String?> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return null;

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final Reference storageRef = FirebaseStorage.instance.ref().child('product_images/$fileName');
      
      final UploadTask uploadTask = storageRef.putFile(File(image.path));
      final TaskSnapshot taskSnapshot = await uploadTask;
      
      return await taskSnapshot.ref.getDownloadURL();
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
    String? mainImagePath,
  ) {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product name is required')),
      );
      return false;
    }

    if (price.isEmpty || double.tryParse(price) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid price')),
      );
      return false;
    }

    if (stock.isEmpty || int.tryParse(stock) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid stock quantity')),
      );
      return false;
    }

    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a category')),
      );
      return false;
    }

    if (mainImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload a main image')),
      );
      return false;
    }

    return true;
  }

  void _showProductSelectionDialog(List<Product> products) {
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Product'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  leading: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.error,
                              color: Colors.red,
                            ),
                          ),
                        )
                      : Icon(Icons.image_not_supported),
                  title: Text(
                    product.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    '${product.category} - \$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showProductDetails(product);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProductDetails(Product product) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(product.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                Text(
                  'Category: ${product.category}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Price: \$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Stock: ${product.stock}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (product.description != null) ...[
                  SizedBox(height: 16),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    product.description!,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            if (_isAdmin)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showEditProductDialog(product);
                },
                child: Text('Edit'),
              ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(Product product) {
    _currentProductId = product.id;
    _showAddProductDialog();
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
    required this.stock,
  });
}
