import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';

class CategoriesSection extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoriesSection({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCategoriesHeader(context),
        _buildCategoriesRow(context),
      ],
    );
  }

  Widget _buildCategoriesHeader(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final specialColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : null;

    return Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.categories,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          PopupMenuButton<String>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort,
                  size: 20,
                  color: themeNotifier.isSpecialModeActive
                      ? specialColor
                      : (themeNotifier.isBlackMode
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.red.shade700),
                ),
                SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.sort,
                  style: TextStyle(
                    color: themeNotifier.isSpecialModeActive
                        ? specialColor
                        : (themeNotifier.isBlackMode
                            ? Theme.of(context).colorScheme.secondary
                            : Colors.red.shade700),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            onSelected: (String value) {
              // Handle sorting
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'price_asc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 20),
                    SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.priceLowToHigh),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'price_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 20),
                    SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.priceHighToLow),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'name_asc',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 20),
                    SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.nameAToZ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'name_desc',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 20),
                    SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.nameZToA),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          ...categories
              .map(
                (category) => Row(
                  children: [
                    _buildCategoryCircle(
                      context,
                      category['name'],
                      category['iconPath'],
                      selectedCategory == category['name'],
                      () => onCategorySelected(category['name']),
                      false,
                    ),
                    SizedBox(width: 15),
                  ],
                ),
              )
              .toList(),
          _buildCategoryCircle(
            context,
            "All",
            'lib/assets/Images/all-icon.png',
            selectedCategory == "All",
            () => onCategorySelected("All"),
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCircle(
    BuildContext context,
    String label,
    String imagePath,
    bool isSelected,
    VoidCallback onTap,
    bool isAsset,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final specialColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : null;

    final selectedBgColor = themeNotifier.isSpecialModeActive
        ? (isDark ? specialColor : specialColor?.withOpacity(0.1))
        : (isDark
            ? (themeNotifier.isBlackMode
                ? Theme.of(context).colorScheme.secondary
                : Colors.red.shade900)
            : Colors.red.shade50);

    final unselectedBgColor =
        isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    final borderColor = themeNotifier.isSpecialModeActive
        ? specialColor
        : (isDark
            ? (themeNotifier.isBlackMode
                ? Theme.of(context).colorScheme.secondary
                : Colors.red.shade700)
            : Colors.red.shade400);

    final shadowColor = themeNotifier.isSpecialModeActive
        ? (specialColor ?? Colors.red).withOpacity(isDark ? 0.5 : 0.3)
        : (isDark
            ? (themeNotifier.isBlackMode
                ? Theme.of(context).colorScheme.secondary.withOpacity(0.5)
                : Colors.red.shade900.withOpacity(0.5))
            : Colors.red.shade300.withOpacity(0.5));

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? selectedBgColor : unselectedBgColor,
              border: isSelected
                  ? Border.all(
                      color: borderColor ?? Colors.red,
                      width: 2,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            padding: EdgeInsets.all(10),
            child: isAsset
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    color: isDark ? Colors.white60 : null,
                  )
                : ColorFiltered(
                    colorFilter: isDark
                        ? ColorFilter.mode(
                            Colors.white70,
                            BlendMode.srcIn,
                          )
                        : ColorFilter.mode(Colors.black, BlendMode.srcIn),
                    child: Image.network(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading category image: $error');
                        return Icon(
                          Icons.category,
                          color: isDark ? Colors.white70 : Colors.grey,
                        );
                      },
                    ),
                  ),
          ),
          SizedBox(height: 8),
          Text(
            _getLocalizedCategoryName(label, context),
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? (themeNotifier.isSpecialModeActive
                      ? specialColor
                      : (isDark
                          ? (themeNotifier.isBlackMode
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.red.shade400)
                          : Colors.red))
                  : (isDark ? Colors.white70 : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedCategoryName(String category, BuildContext context) {
    switch (category) {
      case "All":
        return AppLocalizations.of(context)!.categoryAll;
      case "CPU's":
        return AppLocalizations.of(context)!.categoryCPU;
      case "GPU's":
        return AppLocalizations.of(context)!.categoryGPU;
      case "RAM's":
        return AppLocalizations.of(context)!.categoryRAM;
      case "Storage":
        return AppLocalizations.of(context)!.categoryStorage;
      case "Motherboards":
        return AppLocalizations.of(context)!.categoryMotherboard;
      case "Cases":
        return AppLocalizations.of(context)!.categoryCase;
      case "PSU":
        return AppLocalizations.of(context)!.categoryPSU;
      default:
        return category;
    }
  }
} 