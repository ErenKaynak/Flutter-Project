import 'package:flutter/material.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:engineering_project/pages/Home-Page/widgets/product_card.dart';
import 'package:flutter/scheduler.dart'; // Import for TickerProvider

class ProductGrid extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final List<String> favoriteProductIds;
  final Map<String, AnimationController> animationControllers;
  final Map<String, bool> isAddingToCartMap;
  final Function(Map<String, dynamic>) onAddToCart;
  final Function(Map<String, dynamic>) onToggleFavorite;
  final Function(Map<String, dynamic>) onProductTap;
  final TickerProvider vsync; // Add vsync parameter

  const ProductGrid({
    Key? key,
    required this.products,
    required this.favoriteProductIds,
    required this.animationControllers,
    required this.isAddingToCartMap,
    required this.onAddToCart,
    required this.onToggleFavorite,
    required this.onProductTap,
    required this.vsync, // Add vsync to constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 70, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noProductsFound,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.tryDifferentSearch,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(10),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5,
          mainAxisSpacing: 10,
          childAspectRatio: 0.5,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = products[index];
          final String productId = product['id']?.toString() ?? '';
          final int stock = product["stock"] is int ? product["stock"] : 0;
          final bool isOutOfStock = stock <= 0;
          final bool isFavorite = favoriteProductIds.contains(productId);

          return ProductCard(
            product: product,
            isOutOfStock: isOutOfStock,
            isFavorite: isFavorite,
            animationController: animationControllers[productId] ?? AnimationController(vsync: vsync, duration: Duration(milliseconds: 0)), // Use the passed vsync
            isAddingToCart: isAddingToCartMap[productId] ?? false,
            onAddToCart: () => onAddToCart(product),
            onToggleFavorite: () => onToggleFavorite(product),
            onTap: () => onProductTap(product),
          );
        }, childCount: products.length),
      ),
    );
  }
} 