import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:engineering_project/assets/AI/local_ai_config.dart';
import 'package:engineering_project/screens/cart_screen.dart';
import 'package:engineering_project/pages/product-detail-page.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:engineering_project/providers/cart_provider.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:engineering_project/assets/AI/local_ai_service.dart';
import 'package:engineering_project/assets/AI/imgur_config.dart';
import 'package:engineering_project/assets/components/cart_manager.dart';
import 'package:engineering_project/models/localized_product.dart';
import 'package:engineering_project/pages/cart_page.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:engineering_project/pages/product-detail-page.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' show sin, pi;
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:engineering_project/models/order_models.dart';

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

class AIService {
  Future<String> generateDescription(String productName) async {
    // TODO: Implement actual AI description generation
    return 'A high-quality $productName with excellent performance and durability. Perfect for your needs.';
  }

  Future<String> translateText(String text, String targetLanguage) async {
    // TODO: Implement actual translation
    return text;
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
  _PendingOrderAction? _pendingOrderAction;

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
    if (!mounted) return;
    setState(() {
      _isLocalAIAvailable = isAvailable;
    });

    if (!isAvailable) {
      _showLocalAIError();
    }
  }

  void _showLocalAIError() {
    if (!mounted) return;
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
      // Check for order-related queries
      final lowerText = text.toLowerCase();
      if (lowerText.contains('order') || 
          lowerText.contains('purchase') || 
          lowerText.contains('bought')) {
        
        // Extract time period
        final days = _extractDaysPeriod(text);
        
        // Get orders
        final orders = await _getUserOrders(days);
        
        String response;
        if (orders.isEmpty) {
          response = days == 30 
            ? "I couldn't find any orders in your history."
            : "I couldn't find any orders in the past $days days.";
        } else {
          response = "Here ${orders.length == 1 ? 'is' : 'are'} your ${orders.length} " +
                    "order${orders.length == 1 ? '' : 's'} from the past $days days:";
        }

        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            orders: orders,
          ));
        });
        return;
      }

      // Check if the message is asking for orders
      if (text.toLowerCase().contains('show me orders') ||
          text.toLowerCase().contains('show me my orders') ||
          text.toLowerCase().contains('my orders') ||
          text.toLowerCase().contains('order history')) {
        
        // Extract number of days from the message
        int days = 30; // Default to 30 days
        final daysMatch = RegExp(r'(\d+)\s*days?').firstMatch(text.toLowerCase());
        if (daysMatch != null) {
          days = int.parse(daysMatch.group(1)!);
        }

        // Get orders
        final orders = await _getUserOrders(days);
        
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          if (orders.isNotEmpty) {
            _messages.add(ChatMessage(
              text: '', // No summary text
              isUser: false,
              orders: orders,
            ));
          } else {
            _messages.add(ChatMessage(
              text: 'No orders found in the past $days days.',
              isUser: false,
            ));
          }
        });
      } else if (text.toLowerCase().contains('order status') || 
                 text.toLowerCase().contains('status of order')) {
        // Extract order ID from the message
        final orderIdMatch = RegExp(r'#?(\w+)').firstMatch(text);
        if (orderIdMatch != null) {
          final orderId = orderIdMatch.group(1)!;
          final order = await _getOrderStatus(orderId);
          
          if (!mounted) return;
          setState(() {
            _isTyping = false;
            if (order != null) {
              String statusText = 'Order #${order.id} Status:\n\n';
              statusText += 'Date: ${_formatDate(order.date)}\n';
              statusText += 'Status: ${order.status}\n';
              statusText += 'Total: ₺${order.total.toStringAsFixed(2)}\n\n';
              statusText += 'Items:\n';
              for (var item in order.items) {
                statusText += '• ${item.name} (${item.quantity}x)\n';
              }

              _messages.add(ChatMessage(
                text: statusText,
                isUser: false,
                orders: [order],
              ));
            } else {
              _messages.add(ChatMessage(
                text: 'Order #$orderId not found.',
                isUser: false,
              ));
            }
          });
        } else {
          setState(() {
            _isTyping = false;
            _messages.add(ChatMessage(
              text: 'Please provide an order ID to check its status.',
              isUser: false,
            ));
          });
        }
      } else if (text.toLowerCase().contains('recommend') || 
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
        
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          if (recommendations.isNotEmpty) {
            // Get AI explanations for each product
            _getProductExplanations(recommendations, text).then((explanations) {
              if (!mounted) return;
              setState(() {
                String recommendationText = 'Recommended components:\n\n';
                for (var i = 0; i < recommendations.length; i++) {
                  final product = recommendations[i];
                  final explanation = explanations[i];
                  recommendationText += '• ${product.name}\n';
                  recommendationText += '  ${explanation}\n\n';
                }

                _messages.add(ChatMessage(
                  text: recommendationText,
                  isUser: false,
                  recommendedProducts: recommendations,
                ));
              });
            });
          } else {
            _messages.add(ChatMessage(
              text: 'No suitable components found. Please provide more specific requirements.',
              isUser: false,
            ));
          }
        });
      } else {
        // Regular chat response
        final response = await LocalAIService.getChatCompletion(
          text,
          'You are a PC expert. Give short, clear answers. Use simple language. Keep responses under 100 words.'
        );

        _addMessage(ChatMessage(
          text: response,
          isUser: false,
        ));
      }
    } catch (e) {
      print('Error in chat response: $e');
      _addMessage(ChatMessage(
        text: 'Error occurred. Please try again.',
        isUser: false,
      ));
    }
  }

  // Add this helper function to extract time period from message
  int _extractDaysPeriod(String message) {
    // Look for specific patterns like "2 days", "last 3 days", "past 5 days"
    final daysPattern = RegExp(r'(\d+)(?:\s*(?:day|days))');
    final match = daysPattern.firstMatch(message);
    if (match != null) {
      return int.parse(match.group(1)!);
    }

    // Look for just numbers
    final numberPattern = RegExp(r'\b(\d+)\b');
    final numberMatch = numberPattern.firstMatch(message);
    if (numberMatch != null) {
      return int.parse(numberMatch.group(1)!);
    }

    // Default to 30 days if no number specified
    return 30;
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
            title: Text(
              l10n.aiChatTitle,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: isDark 
                ? themeColor.shade900
                : themeColor.shade700,
            foregroundColor: Colors.white,
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
                      onPressed: () async {
                        if (starter == 'addNewProduct') {
                          _showAddProductDialog();
                        } else if (starter == 'iNeedAssistance') {
                          _launchWhatsApp();
                        } else if (starter == 'updateProduct') {
                          _showProductSearchDialog();
                        } else {
                          // Handle recommendation starters
                          setState(() {
                            _isTyping = true;
                          });

                          try {
                            // Get recommendations based on the starter
                            Map<String, String> preferences = {
                              'use_case': starter == 'lookingForGamingPC' ? 'gaming' : 'general',
                              'cpu_brand': '',
                            };

                            final recommendations = await _getProductRecommendations(localizedText, preferences);
                            
                            if (!mounted) return;
                            if (recommendations.isNotEmpty) {
                              // Get AI explanations for each product
                              _getProductExplanations(recommendations, localizedText).then((explanations) {
                                if (!mounted) return;
                                setState(() {
                                  String recommendationText = 'Recommended components:\n\n';
                                  for (var i = 0; i < recommendations.length; i++) {
                                    final product = recommendations[i];
                                    final explanation = explanations[i];
                                    recommendationText += '• ${product.name}\n';
                                    recommendationText += '  ${explanation}\n\n';
                                  }

                                  _messages.add(ChatMessage(
                                    text: recommendationText,
                                    isUser: false,
                                    recommendedProducts: recommendations,
                                  ));
                                  _isTyping = false;
                                });
                              });
                            } else {
                              setState(() {
                                _messages.add(ChatMessage(
                                  text: 'No suitable components found. Please try a different request.',
                                  isUser: false,
                                ));
                                _isTyping = false;
                              });
                            }
                          } catch (e) {
                            print('Error getting recommendations: $e');
                            if (!mounted) return;
                            setState(() {
                              _isTyping = false;
                              _messages.add(ChatMessage(
                                text: 'Error occurred. Please try again.',
                                isUser: false,
                              ));
                            });
                          }
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
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    return AnimatedBuilder(
      animation: _typingAnimation!,
      builder: (context, child) {
        double opacity = sin(
          (_typingAnimation!.value * pi * 2) - (index * pi / 2),
        );
        opacity = opacity.clamp(0.3, 1.0);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : themeColor).withOpacity(opacity),
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

    // Custom rendering for Yes/No buttons in a card-like box with order info
    if (_pendingOrderAction != null && message.text == _pendingOrderAction!.messageText) {
      final order = _pendingOrderAction!.order;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order info row
              Row(
                children: [
                  Icon(Icons.cancel, color: Colors.orange, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order #${order.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: isDark ? Colors.white54 : Colors.grey[700]),
                  SizedBox(width: 6),
                  Text(
                    _formatDate(order.date),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.account_balance_wallet, size: 18, color: isDark ? Colors.white54 : Colors.blue),
                  SizedBox(width: 6),
                  Text(
                    '₺${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Divider(height: 28, thickness: 1, color: isDark ? Colors.white12 : Colors.grey[200]),
              Text(
                'Order details:\n' + order.items.map((item) => 
                  '${item.quantity}x ${item.name}').join('\n'),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _pendingOrderAction?.onYes?.call();
                        setState(() => _pendingOrderAction = null);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Yes', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pendingOrderAction?.onNo?.call();
                        setState(() => _pendingOrderAction = null);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: themeColor,
                        side: BorderSide(color: themeColor),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('No', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

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
          if (message.orders != null && message.orders!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: message.orders!.map((order) => 
                  _buildOrderCard(order)
                ).toList(),
              ),
            ),
          if (message.recommendedProducts != null && message.recommendedProducts!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: [
                  // Add "Add All to Cart" button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _addAllToCart(message.recommendedProducts!),
                      icon: Icon(Icons.shopping_cart),
                      label: Text('Add All to Cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 45),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  ...message.recommendedProducts!.map((product) => 
                    _buildRecommendationCard(product)
                  ).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    return Container(
      constraints: BoxConstraints(maxWidth: 500),
      child: GestureDetector(
        onTap: () => _sendOrderActionMessage(order),
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: isDark ? Colors.grey.shade800 : Colors.white,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order #${order.id}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      constraints: BoxConstraints(maxWidth: 100),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.status.displayName,
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: isDark ? Colors.white54 : Colors.grey[700]),
                    SizedBox(width: 6),
                    Text(
                      _formatDate(order.date),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.account_balance_wallet, size: 18, color: isDark ? Colors.white54 : Colors.blue),
                    SizedBox(width: 6),
                    Text(
                      '₺${order.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Divider(height: 28, thickness: 1, color: isDark ? Colors.white12 : Colors.grey[200]),
                Text(
                  'Order details:\n' + order.items.map((item) => 
                    '${item.quantity}x ${item.name}').join('\n'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _pendingOrderAction?.onYes?.call();
                          setState(() => _pendingOrderAction = null);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text('Yes', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pendingOrderAction?.onNo?.call();
                          setState(() => _pendingOrderAction = null);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: themeColor,
                          side: BorderSide(color: themeColor),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text('No', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelOrderDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order'),
        content: Text('Do you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(order);
            },
            child: Text('Yes'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showRefundRequestDialog(Order order) {
    final reasonController = TextEditingController();
    final List<XFile> selectedImages = [];
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Request Refund'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason for refund',
                    hintText: 'Please explain why you want a refund',
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final images = await picker.pickMultiImage();
                    if (images != null) {
                      setState(() {
                        selectedImages.addAll(images);
                      });
                    }
                  },
                  icon: Icon(Icons.add_photo_alternate),
                  label: Text('Add Photos (Optional)'),
                ),
                if (selectedImages.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text('${selectedImages.length} images selected'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please provide a reason for your refund request')),
                  );
                  return;
                }

                setState(() => isUploading = true);
                
                try {
                  List<String> imageUrls = [];
                  if (selectedImages.isNotEmpty) {
                    for (var image in selectedImages) {
                      final ref = FirebaseStorage.instance
                          .ref()
                          .child('refund_images')
                          .child('${DateTime.now().millisecondsSinceEpoch}_${image.name}');
                      
                      final uploadTask = await ref.putFile(File(image.path));
                      final imageUrl = await uploadTask.ref.getDownloadURL();
                      imageUrls.add(imageUrl);
                    }
                  }

                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(order.id)
                        .update({
                      'status': OrderStatus.refundRequested.displayName,
                      'refundReason': reasonController.text.trim(),
                      'refundImages': imageUrls,
                      'refundRequestedAt': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Refund request submitted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error submitting refund request: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error submitting refund request: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  setState(() => isUploading = false);
                }
              },
              child: Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelOrder(Order order) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(order.id)
            .update({
          'status': OrderStatus.cancelled.displayName,
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error cancelling order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildRecommendationCard(LocalizedProduct product) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    void navigateToProductDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailPage(
            productId: product.id,
          ),
        ),
      );
    }

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
                GestureDetector(
                  onTap: navigateToProductDetail,
                  child: ClipRRect(
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
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: navigateToProductDetail,
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
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
      )
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.onDelivery:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.refundRequested:
        return Colors.orange;
      case OrderStatus.refundInReview:
        return Colors.blue;
      case OrderStatus.refundApproved:
        return Colors.green;
      case OrderStatus.refundDeclined:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.green.shade700;
      case OrderStatus.cancelled:
        return Colors.red;
    }
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
    final TextEditingController descriptionEnController = TextEditingController();
    final TextEditingController descriptionTrController = TextEditingController();
    final TextEditingController descriptionArController = TextEditingController();
    final TextEditingController descriptionUrController = TextEditingController();
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
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                          ),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            'Product Descriptions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          iconColor: themeColor,
                          collapsedIconColor: themeColor,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Description (English)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  _buildTextField(
                                    controller: descriptionEnController,
                                    label: 'English Description',
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

                                        await _generateAIDescription(
                                          descriptionEnController,
                                          descriptionTrController,
                                          descriptionArController,
                                          descriptionUrController,
                                          nameController.text,
                                        );
                                      },
                                      tooltip: l10n.generateAIDescription,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Description (Turkish)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  _buildTextField(
                                    controller: descriptionTrController,
                                    label: 'Turkish Description',
                                    isDark: isDark,
                                    maxLines: 3,
                                    prefixIcon: Icons.description,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Description (Arabic)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  _buildTextField(
                                    controller: descriptionArController,
                                    label: 'Arabic Description',
                                    isDark: isDark,
                                    maxLines: 3,
                                    prefixIcon: Icons.description,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Description (Urdu)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  _buildTextField(
                                    controller: descriptionUrController,
                                    label: 'Urdu Description',
                                    isDark: isDark,
                                    maxLines: 3,
                                    prefixIcon: Icons.description,
                                  ),
                                ],
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
                                  if (mainImagePath == null) {
                                    throw Exception('Please upload a main image');
                                  }
                                  final newProduct = {
                                    'name': nameController.text,
                                    'price': double.parse(priceController.text),
                                    'stock': int.parse(stockController.text),
                                    'category': selectedCategory,
                                    'descriptions': {
                                      'en': descriptionEnController.text,
                                      'tr': descriptionTrController.text,
                                      'ar': descriptionArController.text,
                                      'ur': descriptionUrController.text,
                                    },
                                    'imagePath': mainImagePath,
                                    'images': [mainImagePath, ...additionalImagePaths],
                                    'createdAt': FieldValue.serverTimestamp(),
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  };
                                  await FirebaseFirestore.instance
                                      .collection('products')
                                      .add(newProduct);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Product added successfully')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error adding product: $e')),
                                  );
                                }
                              }
                            },
                            child: Text(l10n.addNewProduct),
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
    // Move these outside the builder so they persist
    List<LocalizedProduct> searchResults = [];
    bool isSearching = false;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
            final isDark = themeNotifier.isDarkMode;
            final themeColor = themeNotifier.isSpecialModeActive 
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                : Colors.red;
            return Dialog(
              backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.updateProduct,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchProducts,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) async {
                        print('[DEBUG] Product search query: '
                            '\u001b[32m' + value + '\u001b[0m');
                        setState(() {
                          isSearching = true;
                        });
                        final results = await _searchProducts(value);
                        print('[DEBUG] Search returned '+results.length.toString()+' results');
                        for (final p in results) {
                          print('[DEBUG] Found product: ' + p.name);
                        }
                        setState(() {
                          searchResults = results;
                          isSearching = false;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    if (isSearching)
                      Center(child: CircularProgressIndicator()),
                    if (!isSearching && searchResults.isNotEmpty)
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final product = searchResults[index];
                            return ListTile(
                              leading: product.imageUrl.isNotEmpty
                                  ? Image.network(product.imageUrl, width: 40, height: 40, fit: BoxFit.cover)
                                  : null,
                              title: Text(product.name),
                              subtitle: Text('₺${product.price.toStringAsFixed(2)}'),
                              onTap: () {
                                Navigator.pop(context);
                                _showEditProductDialog(product);
                              },
                            );
                          },
                        ),
                      ),
                    if (!isSearching && searchResults.isEmpty && searchController.text.isNotEmpty)
                      Center(child: Text('No products found', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54))),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addAllToCart(List<LocalizedProduct> products) async {
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

  Future<List<Order>> _getUserOrders(int days) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _messages.add(ChatMessage(
          text: 'Please sign in to view your orders.',
          isUser: false,
        ));
        return [];
      }

      print('Fetching orders for user: ${user.uid}');
      
      // Try fetching from main orders collection first
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      print('Found ${ordersSnapshot.docs.length} orders in main collection');

      // If no orders found in main collection, try user's subcollection
      if (ordersSnapshot.docs.isEmpty) {
        print('Trying user subcollection...');
        final userOrdersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .get();

        print('Found ${userOrdersSnapshot.docs.length} orders in user subcollection');
        
        if (userOrdersSnapshot.docs.isEmpty) {
          return [];
        }

        return userOrdersSnapshot.docs.map((doc) {
          final data = doc.data();
          print('Processing user order ${doc.id}:');
          print('Order data: $data');
          
          // Get timestamp from various possible fields
          DateTime orderDate;
          try {
            if (data['timestamp'] != null) {
              orderDate = (data['timestamp'] as Timestamp).toDate();
            } else if (data['createdAt'] != null) {
              orderDate = (data['createdAt'] as Timestamp).toDate();
            } else {
              orderDate = DateTime.now(); // Fallback
            }
          } catch (e) {
            print('Error parsing date: $e');
            orderDate = DateTime.now(); // Fallback
          }

          return Order(
            id: doc.id,
            date: orderDate,
            status: Order._parseOrderStatus(data['status'] as String? ?? 'pending'),
            total: (data['total'] as num?)?.toDouble() ?? 0.0,
            items: (data['items'] as List<dynamic>? ?? []).map((item) => OrderItem(
              name: item['name'] as String? ?? 'Unknown Item',
              quantity: item['quantity'] as int? ?? 1,
              imagePath: item['imagePath'] as String?,
            )).toList(),
          );
        }).toList();
      }

      // Process orders from main collection
      return ordersSnapshot.docs.map((doc) {
        final data = doc.data();
        print('Processing main order ${doc.id}:');
        print('Order data: $data');

        // Get timestamp from various possible fields
        DateTime orderDate;
        try {
          if (data['timestamp'] != null) {
            orderDate = (data['timestamp'] as Timestamp).toDate();
          } else if (data['createdAt'] != null) {
            orderDate = (data['createdAt'] as Timestamp).toDate();
          } else {
            orderDate = DateTime.now(); // Fallback
          }
        } catch (e) {
          print('Error parsing date: $e');
          orderDate = DateTime.now(); // Fallback
        }

        return Order(
          id: doc.id,
          date: orderDate,
          status: Order._parseOrderStatus(data['status'] as String? ?? 'pending'),
          total: (data['total'] as num?)?.toDouble() ?? 0.0,
          items: (data['items'] as List<dynamic>? ?? []).map((item) => OrderItem(
            name: item['name'] as String? ?? 'Unknown Item',
            quantity: item['quantity'] as int? ?? 1,
            imagePath: item['imagePath'] as String?,
          )).toList(),
        );
      }).toList();

    } catch (e, stackTrace) {
      print('Error fetching orders: $e');
      print('Stack trace: $stackTrace');
      _messages.add(ChatMessage(
        text: 'Sorry, I encountered an error while fetching your orders. Error: $e',
        isUser: false,
      ));
      return [];
    }
  }

  Future<Order?> _getOrderStatus(String orderId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Query the main orders collection instead of user's subcollection
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) return null;

      final data = orderDoc.data()!;
      
      // Verify this order belongs to the current user
      if (data['userId'] != user.uid) return null;

      return Order(
        id: orderDoc.id,
        date: (data['createdAt'] as Timestamp).toDate(),
        status: Order._parseOrderStatus(data['status'] as String? ?? 'pending'),
        total: (data['total'] as num).toDouble(),
        items: (data['items'] as List<dynamic>).map((item) => OrderItem(
          name: item['name'] as String,
          quantity: item['quantity'] as int,
          imagePath: item['imagePath'] as String?,
        )).toList(),
      );
    } catch (e) {
      print('Error fetching order status: $e');
      return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<List<String>> _getProductExplanations(List<LocalizedProduct> products, String userQuery) async {
    List<String> explanations = [];
    try {
      for (var product in products) {
        final response = await LocalAIService.getChatCompletion(
          'Why would ${product.name} be a good choice based on this request: "$userQuery"? Keep it under 50 words.',
          'You are a PC hardware expert. Be concise and clear.'
        );

        explanations.add(response);
      }
    } catch (e) {
      print('Error getting product explanations: $e');
      // Return generic explanations if AI service fails
      explanations = List.filled(products.length, 'This component matches your requirements.');
    }
    return explanations;
  }

  Future<void> _checkAdminStatus() async {
    print('Checking admin status...'); // Debug print
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in'); // Debug print
        if (mounted) {
          setState(() => _isAdmin = false);
        }
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
          // Check if the role is admin and user is verified
          _isAdmin = userDoc.exists && 
                    userDoc.data()?['role'] == 'admin' && 
                    user.emailVerified;
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
            // Check if the role is admin and user is verified
            _isAdmin = doc.exists && 
                      doc.data()?['role'] == 'admin' && 
                      FirebaseAuth.instance.currentUser?.emailVerified == true;
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

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
      _isTyping = false;
    });
  }

  List<String> _getFilteredStarters() {
    print('Getting filtered starters. Is admin: $_isAdmin'); // Debug print
    final List<String> starters = List.from(_conversationStarters);

    // If user is not admin, remove admin-only options
    if (!_isAdmin) {
      starters.removeWhere((starter) => 
        starter == 'addNewProduct' || 
        starter == 'updateProduct'
      );
    }

    return starters;
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

  Future<List<LocalizedProduct>> _getProductRecommendations(
    String message,
    Map<String, String> preferences,
  ) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final List<LocalizedProduct> recommendations = [];

      print('Starting product recommendations search with preferences: $preferences');

      // Extract CPU brand preference from message if not already set
      if (preferences['cpu_brand'] == null || preferences['cpu_brand']!.isEmpty) {
        if (message.toLowerCase().contains('amd')) {
          preferences['cpu_brand'] = 'amd';
        } else if (message.toLowerCase().contains('intel')) {
          preferences['cpu_brand'] = 'intel';
        }
      }

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
        // Normalize category names
        final normalizedCategory = category.replaceAll('\'', '');
        productsByCategory.putIfAbsent(normalizedCategory, () => []).add(doc);
      }

      // Define required categories in order of priority
      final requiredCategories = ['CPUs', 'Motherboards', 'GPUs', 'RAMs'];
      final isGaming = preferences['use_case'] == 'gaming';
      final isBudget = message.toLowerCase().contains('budget') ||
          message.toLowerCase().contains('cheap');

      // First, select CPU
      if (productsByCategory.containsKey('CPUs')) {
        var cpus = productsByCategory['CPUs']!;
        
        // Filter by brand if specified
        if (preferences['cpu_brand'] != null && preferences['cpu_brand']!.isNotEmpty) {
          print('Filtering CPUs by brand: ${preferences['cpu_brand']}');
          cpus = cpus.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] as String).toLowerCase();
            final brand = preferences['cpu_brand']!.toLowerCase();
            return name.contains(brand);
          }).toList();
          print('Found ${cpus.length} CPUs for brand ${preferences['cpu_brand']}');
        }

        // Sort CPUs based on requirements
        cpus.sort((a, b) {
          final priceA = (a.data() as Map<String, dynamic>)['price'] as num;
          final priceB = (b.data() as Map<String, dynamic>)['price'] as num;
          
          if (isBudget) {
            return priceA.compareTo(priceB);
          } else if (isGaming) {
            return priceB.compareTo(priceA);
          } else {
            return priceA.compareTo(priceB);
          }
        });

        if (cpus.isNotEmpty) {
          recommendations.add(LocalizedProduct.fromFirestore(cpus.first));
          final cpuData = cpus.first.data() as Map<String, dynamic>;
          print('Selected CPU: ${cpuData['name']}');
        } else {
          print('No CPUs found matching criteria');
          return [];
        }
      }

      // Process remaining categories
      for (final category in requiredCategories.skip(1)) { // Skip CPU as it's already processed
        if (!productsByCategory.containsKey(category)) {
          print('Category not found: $category');
          continue;
        }

        var products = productsByCategory[category]!;
        print('Processing category: $category with ${products.length} products');

        // Sort products based on requirements
        products.sort((a, b) {
          final priceA = (a.data() as Map<String, dynamic>)['price'] as num;
          final priceB = (b.data() as Map<String, dynamic>)['price'] as num;
          
          if (isBudget) {
            return priceA.compareTo(priceB);
          } else if (isGaming) {
            return priceB.compareTo(priceA);
          } else {
            return priceA.compareTo(priceB);
          }
        });

        // Special handling for specific categories
        if (category == 'Motherboards') {
          // For gaming builds, prioritize higher-end motherboards
          if (isGaming) {
            products = products.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] as String).toLowerCase();
              return name.contains('z') || name.contains('x') || name.contains('b');
            }).toList();
          }
        }

        if (category == 'GPUs') {
          // Always include a GPU, with gaming-specific filtering
          if (isGaming) {
            products = products.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] as String).toLowerCase();
              return name.contains('rtx') || name.contains('rx') || name.contains('gtx');
            }).toList();
          }
        }

        if (category == 'RAMs') {
          // Always include RAM, with gaming-specific filtering
          if (isGaming) {
            products = products.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] as String).toLowerCase();
              return name.contains('16gb') || name.contains('32gb');
            }).toList();
          }
        }

        // Add the best matching product from this category
        if (products.isNotEmpty) {
          recommendations.add(LocalizedProduct.fromFirestore(products.first));
          final productData = products.first.data() as Map<String, dynamic>;
          print('Added ${productData['name']} from category $category');
        } else {
          print('No products found for category $category');
          return [];
        }
      }

      // Verify we have all required components
      if (recommendations.length < requiredCategories.length) {
        print('Warning: Could not find products for all required categories');
        return [];
      }

      // Add PSU if available (optional component)
      if (productsByCategory.containsKey('PSU')) {
        var psus = productsByCategory['PSU']!;
        
        // Sort PSUs based on requirements
        psus.sort((a, b) {
          final priceA = (a.data() as Map<String, dynamic>)['price'] as num;
          final priceB = (b.data() as Map<String, dynamic>)['price'] as num;
          
          if (isBudget) {
            return priceA.compareTo(priceB);
          } else if (isGaming) {
            return priceB.compareTo(priceA);
          } else {
            return priceA.compareTo(priceB);
          }
        });

        // For gaming builds, ensure we get a higher wattage PSU
        if (isGaming) {
          psus = psus.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] as String).toLowerCase();
            return name.contains('750w') || name.contains('850w') || name.contains('1000w');
          }).toList();
        }

        if (psus.isNotEmpty) {
          recommendations.add(LocalizedProduct.fromFirestore(psus.first));
        }
      }

      return recommendations;
    } catch (e) {
      print('Error getting product recommendations: $e');
      return [];
    }
  }

  void _addToCart(LocalizedProduct product) async {
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

  Future<List<LocalizedProduct>> _searchProducts(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final snapshot = await FirebaseFirestore.instance.collection('products').get();

      return snapshot.docs
          .map((doc) => LocalizedProduct.fromFirestore(doc))
          .where((product) {
            // Search in name, category, and all descriptions
            final nameMatch = product.name.toLowerCase().contains(lowerQuery);
            final categoryMatch = product.category.toLowerCase().contains(lowerQuery);
            final descriptionMatch = product.descriptions.values.any((desc) => desc.toLowerCase().contains(lowerQuery));
            return nameMatch || categoryMatch || descriptionMatch;
          })
          .toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  void _showProductSelectionDialog(List<LocalizedProduct> products) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;

    // TODO: Replace dialog with inline UI or chat message if needed.
    // showDialog(...)
  }

  void _showEditProductDialog(LocalizedProduct product) {
    final TextEditingController nameController = TextEditingController(text: product.name);
    final TextEditingController priceController = TextEditingController(text: product.price.toString());
    final TextEditingController stockController = TextEditingController(text: product.stock.toString());
    final TextEditingController descriptionEnController = TextEditingController(text: product.getDescription('en'));
    final TextEditingController descriptionTrController = TextEditingController(text: product.getDescription('tr'));
    final TextEditingController descriptionArController = TextEditingController(text: product.getDescription('ar'));
    final TextEditingController descriptionUrController = TextEditingController(text: product.getDescription('ur'));
    String? selectedCategory = product.category;
    String? mainImagePath = product.imageUrl;
    List<String> additionalImagePaths = List.from(product.images);
    _currentProductId = product.id;

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
                        l10n.updateProduct,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: isDark ? Colors.white : Colors.black,
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
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                          ),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            'Product Descriptions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          iconColor: themeColor,
                          collapsedIconColor: themeColor,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Description (English)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  _buildTextField(
                                    controller: descriptionEnController,
                                    label: 'English Description',
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

                                        await _generateAIDescription(
                                          descriptionEnController,
                                          descriptionTrController,
                                          descriptionArController,
                                          descriptionUrController,
                                          nameController.text,
                                        );
                                      },
                                      tooltip: l10n.generateAIDescription,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Description (Turkish)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  _buildTextField(
                                    controller: descriptionTrController,
                                    label: 'Turkish Description',
                                    isDark: isDark,
                                    maxLines: 3,
                                    prefixIcon: Icons.description,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Description (Arabic)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  _buildTextField(
                                    controller: descriptionArController,
                                    label: 'Arabic Description',
                                    isDark: isDark,
                                    maxLines: 3,
                                    prefixIcon: Icons.description,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Description (Urdu)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  _buildTextField(
                                    controller: descriptionUrController,
                                    label: 'Urdu Description',
                                    isDark: isDark,
                                    maxLines: 3,
                                    prefixIcon: Icons.description,
                                  ),
                                ],
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
                                  if (mainImagePath == null) {
                                    throw Exception('Please upload a main image');
                                  }

                                  final updatedProduct = {
                                    'name': nameController.text,
                                    'price': double.parse(priceController.text),
                                    'stock': int.parse(stockController.text),
                                    'category': selectedCategory,
                                    'descriptions': {
                                      'en': descriptionEnController.text,
                                      'tr': descriptionTrController.text,
                                      'ar': descriptionArController.text,
                                      'ur': descriptionUrController.text,
                                    },
                                    'imagePath': mainImagePath,
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
              ));
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    Widget? suffixIcon,
    int maxLines = 1,
     }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: isDark ? Colors.white70 : Colors.black54,
              )
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }

  Future<List<String>> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('categories').orderBy('name').get();
      // Use the 'name' field for display, not the document ID
      return snapshot.docs.map((doc) => doc.data()['name']?.toString() ?? doc.id).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<void> _generateAIDescription(
    TextEditingController enController,
    TextEditingController trController,
    TextEditingController arController,
    TextEditingController urController,
    String productName,
  ) async {
    try {
      final aiService = AIService();
      final enDescription = await aiService.generateDescription(productName);
      enController.text = enDescription;

      final trDescription = await aiService.translateText(enDescription, 'tr');
      trController.text = trDescription;

      final arDescription = await aiService.translateText(enDescription, 'ar');
      arController.text = arDescription;

      final urDescription = await aiService.translateText(enDescription, 'ur');
      urController.text = urDescription;
    } catch (e) {
      print('Error generating AI description: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating description: $e')),
      );
    }
  }

  Future<String?> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return null;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(File(image.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error picking/uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
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
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product name')),
      );
      return false;
    }

    if (price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a price')),
      );
      return false;
    }

    if (double.tryParse(price) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return false;
    }

    if (stock.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter stock quantity')),
      );
      return false;
    }

    if (int.tryParse(stock) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid stock quantity')),
      );
      return false;
    }

    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return false;
    }

    if (mainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a main image')),
      );
      return false;
    }

    return true;
  }

  void _sendOrderActionMessage(Order order) {
    final message = ChatMessage(
      text: "Would you like to perform any actions on Order #${order.id}?",
      isUser: false,
    );
    setState(() {
      _messages.add(message);
    });
  }
}

/// Represents the possible states of an order
enum OrderStatus {
  pending,
  preparing,
  onDelivery,
  delivered,
  refundRequested,
  refundInReview,
  refundApproved,
  refundDeclined,
  refunded,
  cancelled;

  /// Gets the display name for the order status
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.onDelivery:
        return 'On Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.refundRequested:
        return 'Refund Requested';
      case OrderStatus.refundInReview:
        return 'Refund In Review';
      case OrderStatus.refundApproved:
        return 'Refund Approved';
      case OrderStatus.refundDeclined:
        return 'Refund Declined';
      case OrderStatus.refunded:
        return 'Refunded';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Represents an order in the system
class Order {
  /// Unique identifier for the order
  final String id;
  
  /// Date when the order was created
  final DateTime date;
  
  /// Current status of the order
  final OrderStatus status;
  
  /// Total amount of the order
  final double total;
  
  /// Items included in the order
  final List<OrderItem> items;
  
  /// Tracking number for delivery (optional)
  final String? trackingNumber;

  /// Creates a new Order instance
  const Order({
    required this.id,
    required this.date,
    required this.status,
    required this.total,
    required this.items,
    this.trackingNumber,
  });

  /// Creates an Order instance from Firestore document
  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Order(
      id: doc.id,
      date: (data['createdAt'] as Timestamp).toDate(),
      status: Order._parseOrderStatus(data['status'] as String? ?? 'pending'),
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      trackingNumber: data['trackingNumber'] as String?,
      items: (data['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Parses a string into an OrderStatus enum
  static OrderStatus _parseOrderStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'preparing':
        return OrderStatus.preparing;
      case 'on delivery':
        return OrderStatus.onDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'refund requested':
        return OrderStatus.refundRequested;
      case 'refund in review':
        return OrderStatus.refundInReview;
      case 'refund approved':
        return OrderStatus.refundApproved;
      case 'refund declined':
        return OrderStatus.refundDeclined;
      case 'refunded':
        return OrderStatus.refunded;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

/// Represents an item within an order
class OrderItem {
  /// Name of the item
  final String name;
  
  /// Quantity ordered
  final int quantity;
  
  /// Path to the item's image (optional)
  final String? imagePath;

  /// Creates a new OrderItem instance
  const OrderItem({
    required this.name,
    required this.quantity,
    this.imagePath,
  });

  /// Creates an OrderItem from a map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      imagePath: map['imagePath'] as String?,
    );
  }
}

/// Represents a pending action on an order
class _PendingOrderAction {
  final Order order;
  final VoidCallback? onYes;
  final VoidCallback? onNo;
  final String messageText;

  const _PendingOrderAction({
    required this.order,
    this.onYes,
    this.onNo,
    required this.messageText,
  });
}

/// Represents a chat message in the conversation
class ChatMessage {
  final String text;
  final bool isUser;
  final List<Order>? orders;
  final List<LocalizedProduct>? recommendedProducts;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.orders,
    this.recommendedProducts,
  });
}
