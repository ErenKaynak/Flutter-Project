import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/pages/theme_notifier.dart';

class MostViewedSection extends StatefulWidget {
  final Function(Map<String, dynamic>) onProductTap;
  final Function(Map<String, dynamic>) onAddToCart;
  final Function(Map<String, dynamic>) onToggleFavorite;
  final List<String> favoriteProductIds;
  final Map<String, AnimationController> animationControllers;
  final Map<String, bool> isAddingToCartMap;
  final TickerProvider vsync;
  final String? selectedCategory;

  const MostViewedSection({
    Key? key,
    required this.onProductTap,
    required this.onAddToCart,
    required this.onToggleFavorite,
    required this.favoriteProductIds,
    required this.animationControllers,
    required this.isAddingToCartMap,
    required this.vsync,
    this.selectedCategory,
  }) : super(key: key);

  @override
  _MostViewedSectionState createState() => _MostViewedSectionState();
}

class _MostViewedSectionState extends State<MostViewedSection> {
  List<Map<String, dynamic>> _mostViewedProducts = [];
  bool _isMostViewedLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMostViewedProducts();
  }

  @override
  void didUpdateWidget(MostViewedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _loadMostViewedProducts();
    }
  }

  Future<void> _loadMostViewedProducts() async {
    if (!mounted) return;
    
    try {
      print('Starting to load most viewed products...'); // Debug log
      setState(() {
        _isMostViewedLoading = true;
      });

      Query query = FirebaseFirestore.instance
          .collection('products')
          .orderBy('viewCount', descending: true);

      // Apply category filter if not "All"
      if (widget.selectedCategory != null && widget.selectedCategory != "All") {
        query = query.where('category', isEqualTo: widget.selectedCategory);
      }

      final QuerySnapshot snapshot = await query.limit(5).get();

      print('Fetched ${snapshot.docs.length} most viewed products'); // Debug log

      if (!mounted) return;

      final List<Map<String, dynamic>> loadedProducts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Product: ${data['name']}, View count: ${data['viewCount']}'); // Debug log
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Product',
          'price': data['price']?.toString() ?? '0',
          'category': data['category'] ?? 'Uncategorized',
          'image': data['imagePath'] ?? 'lib/assets/Images/placeholder.png',
          'description': data['description'] ?? 'No description available',
          'stock': data['stock'] ?? 0,
          'viewCount': data['viewCount'] ?? 0,
          'averageRating': (data['averageRating'] ?? 0.0).toDouble(),
          'ratingCount': data['ratingCount'] ?? 0,
        };
      }).toList();

      setState(() {
        _mostViewedProducts = loadedProducts;
        _isMostViewedLoading = false;
      });
      print('Most viewed products loaded successfully'); // Debug log
    } catch (e) {
      print('Error loading most viewed products: $e');
      if (mounted) {
        setState(() {
          _mostViewedProducts = [];
          _isMostViewedLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building most viewed section. Loading: $_isMostViewedLoading, Products count: ${_mostViewedProducts.length}'); // Debug log
    
    if (_isMostViewedLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_mostViewedProducts.isEmpty) {
      print('No most viewed products to display'); // Debug log
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            AppLocalizations.of(context)!.mostViewed,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          height: 240, // Increased height to accommodate the cart button
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 10),
            itemCount: _mostViewedProducts.length,
            itemBuilder: (context, index) {
              final product = _mostViewedProducts[index];
              final productId = product['id'];
              final isFavorite = widget.favoriteProductIds.contains(productId);
              final isOutOfStock = (product['stock'] ?? 0) <= 0;
              final isAddingToCart = widget.isAddingToCartMap[productId] ?? false;
              final animationController = widget.animationControllers[productId];

              if (animationController == null) {
                widget.animationControllers[productId] = AnimationController(
                  vsync: widget.vsync,
                  duration: Duration(milliseconds: 1000),
                );
              }

              final colorAnimation = ColorTween(
                begin: Provider.of<ThemeNotifier>(context).isSpecialModeActive
                    ? Provider.of<ThemeNotifier>(context).getThemeColor(Provider.of<ThemeNotifier>(context).specialTheme)
                    : (Provider.of<ThemeNotifier>(context).isBlackMode
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.red.shade400),
                end: Colors.green.shade500,
              ).animate(animationController ?? widget.animationControllers[productId]!);

              final opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
                CurvedAnimation(
                  parent: animationController ?? widget.animationControllers[productId]!,
                  curve: Interval(0.3, 0.9, curve: Curves.linear),
                ),
              );

              final tickScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animationController ?? widget.animationControllers[productId]!,
                  curve: Interval(0.3, 0.9, curve: Curves.linear),
                ),
              );

              print('Building product item: ${product['name']} with view count: ${product['viewCount']}'); // Debug log
              return GestureDetector(
                onTap: () => widget.onProductTap(product),
                child: Container(
                  width: 150,
                  margin: EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(
                              product['image'],
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: GestureDetector(
                                onTap: () => widget.onToggleFavorite(product),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: Provider.of<ThemeNotifier>(context).isSpecialModeActive
                                      ? Provider.of<ThemeNotifier>(context).getThemeColor(Provider.of<ThemeNotifier>(context).specialTheme)
                                      : (Provider.of<ThemeNotifier>(context).isBlackMode
                                          ? Theme.of(context).colorScheme.secondary
                                          : Colors.red),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < (product['averageRating'] ?? 0).round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 14,
                                  );
                                }),
                                SizedBox(width: 4),
                                Text(
                                  '(${product['ratingCount'] ?? 0})',
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              '₺${product['price']}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Views: ${product['viewCount']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 32,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                  backgroundColor: colorAnimation.value,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: isOutOfStock || isAddingToCart
                                    ? null
                                    : () => widget.onAddToCart(product),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: opacityAnimation,
                                      builder: (context, child) {
                                        return Opacity(
                                          opacity: opacityAnimation.value,
                                          child: child,
                                        );
                                      },
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (!isOutOfStock)
                                              Icon(Icons.shopping_cart,
                                                  size: 14, color: Colors.white),
                                            if (!isOutOfStock) SizedBox(width: 8),
                                            Text(
                                              isOutOfStock
                                                  ? AppLocalizations.of(context)!.outOfStock
                                                  : AppLocalizations.of(context)!.addToCart,
                                              style: TextStyle(
                                                fontSize: isOutOfStock ? 10 : 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    AnimatedBuilder(
                                      animation: tickScaleAnimation,
                                      builder: (context, child) {
                                        if (tickScaleAnimation.value > 0) {
                                          return Transform.scale(
                                            scale: tickScaleAnimation.value,
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          );
                                        } else {
                                          return SizedBox.shrink();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 