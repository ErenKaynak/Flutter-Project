import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../pages/theme_notifier.dart';

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({Key? key}) : super(key: key);

  @override
  State<AdminStatisticsPage> createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String selectedTimeFrame = 'Monthly';
  List<String> timeFrames = ['Weekly', 'Monthly', 'Yearly'];
  TabController? _tabController;
  
  // Statistics data
  double totalRevenue = 0;
  int totalProducts = 0;
  int totalUsers = 0;
  int totalOrders = 0;
  List<FlSpot> revenueData = [];
  List<FlSpot> ordersData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchStatistics();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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
      Map<DateTime, double> dailyRevenue = {};
      Map<DateTime, int> dailyOrders = {};
      
      // Process filtered orders
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        final items = data['items'] as List<dynamic>? ?? [];
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
        
        for (var item in items) {
          try {
            final quantity = (item['quantity'] as num? ?? 0).toInt();
            final price = double.parse((item['price'] ?? '0').toString());
            
            totalProductCount += quantity;
            totalRevenueAmount += price * quantity;
            
            dailyRevenue[date] = (dailyRevenue[date] ?? 0) + (price * quantity);
            dailyOrders[date] = (dailyOrders[date] ?? 0) + 1;
          } catch (e) {
            print('Error processing item: $e');
            continue;
          }
        }
      }

      // Fetch total users count (all users, not just within time frame)
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      // Prepare chart data
      List<FlSpot> revenueSpots = [];
      List<FlSpot> orderSpots = [];
      int index = 0;
      
      dailyRevenue.forEach((date, revenue) {
        revenueSpots.add(FlSpot(index.toDouble(), revenue));
        orderSpots.add(FlSpot(index.toDouble(), dailyOrders[date]?.toDouble() ?? 0));
        index++;
      });

      setState(() {
        totalRevenue = totalRevenueAmount;
        totalProducts = totalProductCount;
        totalOrders = ordersSnapshot.size;
        totalUsers = usersSnapshot.size; // Total number of users in the system
        revenueData = revenueSpots;
        ordersData = orderSpots;
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
        : (isDark ? Colors.red.shade900 : Colors.red);

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin Statistics'),
        backgroundColor: themeColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: fetchStatistics,
              color: themeColor,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(themeColor, isDark),
                  _buildAnalyticsTab(themeColor, isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            height: 100,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              children: List.generate(4, (index) => Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Color themeColor, bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeFrameSelector(),
          const SizedBox(height: 20),
          _buildStatisticsCards(),
          const SizedBox(height: 24),
          _buildQuickActions(themeColor, isDark),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(Color themeColor, bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRevenueChart(themeColor, isDark),
          const SizedBox(height: 24),
          _buildOrdersChart(themeColor, isDark),
        ],
      ),
    );
  }

  Widget _buildTimeFrameSelector() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: timeFrames.map((frame) {
          final isSelected = frame == selectedTimeFrame;
          return GestureDetector(
            onTap: () {
              setState(() => selectedTimeFrame = frame);
              fetchStatistics();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? themeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                frame,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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

  Widget _buildQuickActions(Color themeColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(
              'Export Data',
              Icons.download,
              themeColor,
              () {
                // Implement export functionality
              },
            ),
            _buildActionButton(
              'Print Report',
              Icons.print,
              themeColor,
              () {
                // Implement print functionality
              },
            ),
            _buildActionButton(
              'Share',
              Icons.share,
              themeColor,
              () {
                // Implement share functionality
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(Color themeColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: revenueData,
                    isCurved: true,
                    color: themeColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: themeColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersChart(Color themeColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orders Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: ordersData,
                    isCurved: true,
                    color: themeColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: themeColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}