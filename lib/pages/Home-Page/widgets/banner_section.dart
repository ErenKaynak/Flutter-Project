import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/pages/theme_notifier.dart';

class BannerSection extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  final bool isLoading;
  final Function(int, CarouselPageChangedReason) onPageChanged;

  const BannerSection({
    Key? key,
    required this.banners,
    required this.isLoading,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  _BannerSectionState createState() => _BannerSectionState();
}

class _BannerSectionState extends State<BannerSection> {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final currentTheme = themeNotifier.specialTheme.toString().split('.').last.toLowerCase();
    
    // Filter banners based on special theme or show red themed banners by default
    final displayedBanners = themeNotifier.isSpecialModeActive
        ? widget.banners.where((banner) {
            final bannerTheme = (banner['themeColor'] ?? '').toLowerCase();
            return bannerTheme == currentTheme;
          }).toList()
        : widget.banners.where((banner) => 
            (banner['themeColor'] ?? '').toLowerCase() == 'red').toList();

    if (widget.isLoading) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[200],
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (displayedBanners.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[200],
        ),
        child: Center(
          child: Text('No banners available'),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      height: 180,
      child: CarouselSlider(
        options: CarouselOptions(
          height: 180,
          autoPlay: true,
          autoPlayInterval: Duration(seconds: 3),
          enlargeCenterPage: true,
          viewportFraction: 1.0,
          onPageChanged: widget.onPageChanged,
        ),
        items: displayedBanners.map((banner) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                width: MediaQuery.of(context).size.width,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    banner['imageUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error),
                      );
                    },
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
} 