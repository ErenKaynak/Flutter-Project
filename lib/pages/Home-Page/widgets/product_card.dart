import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isOutOfStock;
  final bool isFavorite;
  final AnimationController animationController;
  final bool isAddingToCart;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const ProductCard({
    Key? key,
    required this.product,
    required this.isOutOfStock,
    required this.isFavorite,
    required this.animationController,
    required this.isAddingToCart,
    required this.onAddToCart,
    required this.onToggleFavorite,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final specialColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : null;

    final colorAnimation = ColorTween(
      begin: themeNotifier.isSpecialModeActive
          ? specialColor
          : (themeNotifier.isBlackMode
              ? Theme.of(context).colorScheme.secondary
              : Colors.red.shade400),
      end: Colors.grey.shade800,
    ).animate(animationController);

    final opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: animationController, curve: Interval(0.3, 0.9, curve: Curves.linear)));

    final tickScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(0.3, 0.9, curve: Curves.linear),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade900
                        : Colors.grey[200],
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          (product["image"] ?? 'lib/assets/Images/placeholder.png') as String,
                          fit: BoxFit.cover,
                          height: double.infinity,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.error),
                            );
                          },
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
                            onTap: onToggleFavorite,
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: themeNotifier.isSpecialModeActive
                                  ? specialColor
                                  : (themeNotifier.isBlackMode
                                      ? Theme.of(context).colorScheme.secondary
                                      : Colors.red),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ((product["name"] ?? "İsimsiz Ürün") as String).length > 17
                                  ? ((product["name"] ?? "İsimsiz Ürün") as String).substring(0, 17) + '...'
                                  : (product["name"] ?? "İsimsiz Ürün") as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                            SizedBox(height: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ...List.generate(5, (index) {
                                      return Icon(
                                        index < ((product['averageRating'] ?? 0) as num).round()
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
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              _formatPrice(product["price"] ?? '0'),
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 0),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            backgroundColor: colorAnimation.value,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          onPressed: isOutOfStock || isAddingToCart
                              ? null
                              : onAddToCart,
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
                                            size: 16, color: Colors.white),
                                      if (!isOutOfStock) SizedBox(width: 8),
                                      Text(
                                        isOutOfStock
                                            ? AppLocalizations.of(context)!
                                                .outOfStock
                                            : AppLocalizations.of(context)!
                                                .addToCart,
                                        style: TextStyle(
                                          fontSize: isOutOfStock ? 12 : 14,
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
                                  }
                                  return SizedBox.shrink();
                                },
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

  String _formatPrice(String price) {
    try {
      final double numericPrice = double.parse(price);
      return '₺${numericPrice.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          )}';
    } catch (e) {
      return '₺0.00';
    }
  }
} 