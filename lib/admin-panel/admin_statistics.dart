import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../pages/theme_notifier.dart';

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({Key? key}) : super(key: key);

  @override
  _AdminStatisticsPageState createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> {
  bool isLoading = true;
  String selectedTimeFrame = 'Monthly';
  List<String> timeFrames = ['Weekly', 'Monthly', 'Yearly'];
  
  // Statistics data
  double totalRevenue = 0;
  int totalProducts = 0;
  int totalUsers = 0;
  int totalOrders = 0;

  @override
  void initState() {
    super.initState();
    fetchStatistics();
  }

  Future<void> fetchStatistics() async {
    setState(() => isLoading = true);
    
    try {
      final DateTime now = DateTime.now();
      final DateTime startDate = getStartDate(now);

      // Get orders within the selected time frame
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: now)
          .get();
      
      // Calculate total products from filtered orders
      int totalProductCount = 0;
      double totalRevenueAmount = 0;
      
      // Process filtered orders
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        final items = data['items'] as List<dynamic>? ?? [];
        
        for (var item in items) {
          try {
            final quantity = (item['quantity'] as num? ?? 0).toInt();
            final price = double.parse((item['price'] ?? '0').toString());
            
            totalProductCount += quantity;
            totalRevenueAmount += price * quantity;
          } catch (e) {
            print('Error processing item: $e');
            continue;
          }
        }
      }

      // Fetch users count within the time frame
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: now)
          .get();

      print('Debug Statistics for ${selectedTimeFrame}:');
      print('Start Date: $startDate');
      print('End Date: $now');
      print('Total Products Sold: $totalProductCount');
      print('Total Revenue: $totalRevenueAmount');
      print('Total Orders: ${ordersSnapshot.size}');

      setState(() {
        totalRevenue = totalRevenueAmount;
        totalProducts = totalProductCount;
        totalOrders = ordersSnapshot.size;
        totalUsers = usersSnapshot.size;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching statistics: $e');
      setState(() => isLoading = false);
    }
  }

  DateTime getStartDate(DateTime now) {
    switch (selectedTimeFrame) {
      case 'Weekly':
        return now.subtract(const Duration(days: 7));
      case 'Monthly':
        return now.subtract(const Duration(days: 30));
      case 'Yearly':
        return now.subtract(const Duration(days: 365));
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : (isDark ? Colors.red.shade900 : Colors.red.shade700);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Statistics',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: isDark ? Colors.red.shade900 : Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: isDark ? 0 : 2,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(
              color: themeColor,
            ))
          : RefreshIndicator(
              onRefresh: fetchStatistics,
              color: themeColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeFrameSelector(),
                    const SizedBox(height: 20),
                    _buildStatisticsCards(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimeFrameSelector() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: timeFrames.map((frame) {
        final isSelected = frame == selectedTimeFrame;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ChoiceChip(
            label: Text(frame),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => selectedTimeFrame = frame);
                fetchStatistics();
              }
            },
            selectedColor: themeColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatisticsCards() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total Revenue',
          '₺${NumberFormat('#,##0.00', 'tr_TR').format(totalRevenue)}',
          Icons.monetization_on,
          themeColor,
        ),
        _buildStatCard(
          'Products Sold',
          NumberFormat('#,##0', 'tr_TR').format(totalProducts),
          Icons.inventory,
          themeColor,
        ),
        _buildStatCard(
          'Total Users',
          NumberFormat('#,##0', 'tr_TR').format(totalUsers),
          Icons.people,
          themeColor,
        ),
        _buildStatCard(
          'Total Orders',
          NumberFormat('#,##0', 'tr_TR').format(totalOrders),
          Icons.shopping_cart,
          themeColor,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}