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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : (isDark ? Colors.red.shade900 : Colors.red);

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDark 
            ? (themeNotifier.isSpecialModeActive 
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade900 
                : Colors.red.shade900)
            : (themeNotifier.isSpecialModeActive 
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade700 
                : Colors.red.shade700),
        title: const Text(
          'Admin Statistics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.white,
        elevation: isDark ? 0 : 2,
      ),
      body: isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: fetchStatistics,
              color: themeColor,
              child: _buildOverviewTab(themeColor, isDark),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading statistics...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
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

      // Fetch total users count (all users, not just within time frame)
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      setState(() {
        totalRevenue = totalRevenueAmount;
        totalProducts = totalProductCount;
        totalOrders = ordersSnapshot.size;
        totalUsers = usersSnapshot.size;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching statistics: $e');
      setState(() {
        isLoading = false;
      });
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

  Widget _buildTimeFrameSelector() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              'Export Data',
              Icons.download,
              themeColor,
              () async {
                try {
                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                      ),
                    ),
                  );

                  // Get the data
                  final ordersSnapshot = await FirebaseFirestore.instance
                      .collection('orders')
                      .where('timestamp', isGreaterThanOrEqualTo: getStartDate(DateTime.now()))
                      .get();

                  // Format the data
                  final data = ordersSnapshot.docs.map((doc) {
                    final order = doc.data();
                    return {
                      'Order ID': doc.id,
                      'Date': (order['timestamp'] as Timestamp).toDate().toString(),
                      'Total Amount': order['totalAmount']?.toString() ?? '0',
                      'Status': order['status'] ?? 'Unknown',
                      'Items': (order['items'] as List?)?.length ?? 0,
                    };
                  }).toList();

                  // Create CSV content
                  final csvData = StringBuffer();
                  // Add headers
                  csvData.writeln('Order ID,Date,Total Amount,Status,Items');
                  // Add rows
                  for (var row in data) {
                    csvData.writeln('${row['Order ID']},${row['Date']},${row['Total Amount']},${row['Status']},${row['Items']}');
                  }

                  // Dismiss loading dialog
                  Navigator.pop(context);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Data exported successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // Dismiss loading dialog if it's showing
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error exporting data: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            _buildActionButton(
              'View Reports',
              Icons.assessment,
              themeColor,
              _navigateToReports,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'View detailed analysis',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
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

  // Update the View Reports navigation to use the new report functionality
  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Detailed Reports'),
            backgroundColor: Provider.of<ThemeNotifier>(context).isSpecialModeActive
                ? Provider.of<ThemeNotifier>(context).getThemeColor(Provider.of<ThemeNotifier>(context).specialTheme)
                : Colors.red,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a Report',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'View detailed analytics and insights',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 24),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    children: [
                      _buildReportCard(
                        'Top Selling Products',
                        Icons.trending_up,
                        Provider.of<ThemeNotifier>(context).isSpecialModeActive
                            ? Provider.of<ThemeNotifier>(context).getThemeColor(Provider.of<ThemeNotifier>(context).specialTheme)
                            : Colors.red,
                        () => _showDetailedReport('Top Selling Products'),
                      ),
                      SizedBox(height: 16),
                      _buildReportCard(
                        'Customer Analytics',
                        Icons.people,
                        Provider.of<ThemeNotifier>(context).isSpecialModeActive
                            ? Provider.of<ThemeNotifier>(context).getThemeColor(Provider.of<ThemeNotifier>(context).specialTheme)
                            : Colors.red,
                        () => _showDetailedReport('Customer Analytics'),
                      ),
                      SizedBox(height: 16),
                      _buildReportCard(
                        'Order Status',
                        Icons.shopping_cart,
                        Provider.of<ThemeNotifier>(context).isSpecialModeActive
                            ? Provider.of<ThemeNotifier>(context).getThemeColor(Provider.of<ThemeNotifier>(context).specialTheme)
                            : Colors.red,
                        () => _showDetailedReport('Order Status'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailedReport(String reportType) async {
    // Get theme data before async operation
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final themeColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            ),
            SizedBox(height: 16),
            Text(
              'Loading report...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      Widget reportContent;
      switch (reportType) {
        case 'Top Selling Products':
          final data = await _getTopSellingProducts();
          reportContent = _buildTopProductsReport(data, themeColor);
          break;
        case 'Customer Analytics':
          final data = await _getCustomerAnalytics();
          reportContent = _buildCustomerAnalyticsReport(data, themeColor);
          break;
        case 'Order Status':
          final data = await _getOrderStatus();
          reportContent = _buildOrderStatusReport(data, themeColor);
          break;
        default:
          reportContent = Text('Invalid report type');
      }

      // Dismiss loading dialog
      Navigator.pop(context);

      // Show report dialog
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      reportType,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(),
                Flexible(
                  child: SingleChildScrollView(
                    child: reportContent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // Dismiss loading dialog
      Navigator.pop(context);
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to load report: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTopProductsReport(Map<String, dynamic> data, Color themeColor) {
    final List<String> products = List<String>.from(data['products'] ?? []);
    final List<double> quantities = List<double>.from(data['quantities'] ?? []);
    final List<double> revenues = List<double>.from(data['revenue'] ?? []);

    if (products.isEmpty) {
      return Center(
        child: Text('No product data available for the selected period'),
      );
    }

    // Debug print for list data
    print('Top Products List Data - Products: $products, Revenues: $revenues');

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: quantities.isNotEmpty ? quantities.reduce((a, b) => a > b ? a : b) * 1.2 : 100,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${products[groupIndex]}\n${rod.toY.toInt()} units',
                      TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value >= 0 && value < products.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            products[value.toInt()],
                            style: TextStyle(fontSize: 10),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }
                      return Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              gridData: FlGridData(show: true),
              barGroups: List.generate(
                products.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: quantities[index],
                      color: themeColor,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Revenue by Product',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        // Check if revenues list is also not empty before generating ListTiles
        if (revenues.isNotEmpty)
          ...List.generate(
            products.length,
            (index) => ListTile(
              title: Text(products[index]),
              trailing: Text(
                '₺${NumberFormat('#,##0.00', 'tr_TR').format(revenues[index])}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ),
          ) else Center(child: Text('No revenue data available.')),
      ],
    );
  }

  Widget _buildCustomerAnalyticsReport(Map<String, dynamic> data, Color themeColor) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAnalyticsItem(
                  'Total Customers',
                  data['totalCustomers'].toString(),
                  Icons.people,
                  themeColor,
                ),
                Divider(),
                _buildAnalyticsItem(
                  'Average Order Value',
                  '₺${NumberFormat('#,##0.00', 'tr_TR').format(data['averageOrderValue'])}',
                  Icons.attach_money,
                  themeColor,
                ),
                Divider(),
                _buildAnalyticsItem(
                  'Repeat Customers',
                  data['repeatCustomers'].toString(),
                  Icons.repeat,
                  themeColor,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Customer Insights',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          '• ${data['totalCustomers'] > 0 ? ((data['repeatCustomers'] / data['totalCustomers']) * 100).toStringAsFixed(1) : '0'}% of customers have made multiple purchases\n'
          '• Average customer spends ₺${NumberFormat('#,##0.00', 'tr_TR').format(data['averageOrderValue'])} per order\n'
          '• ${data['totalCustomers']} unique customers in the selected period',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildOrderStatusReport(Map<String, int> data, Color themeColor) {
    if (data.isEmpty) {
      return Center(
        child: Text('No order data available for the selected period'),
      );
    }

    // Debug print for list data
    print('Order Status List Data: $data');

    final totalOrders = data.values.fold(0, (a, b) => a + b);
    final statusColors = {
      'Pending': Colors.orange,
      'Processing': Colors.blue,
      'Shipped': Colors.purple,
      'Delivered': Colors.green,
      'Cancelled': Colors.red,
    };

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: data.entries.map((entry) {
                final percentage = (entry.value / totalOrders) * 100;
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: '${percentage.toStringAsFixed(1)}%',
                  color: statusColors[entry.key] ?? Colors.grey,
                  radius: 100,
                  titleStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              startDegreeOffset: -90,
            ),
          ),
        ),
        SizedBox(height: 20),
        // Check if data is not empty before generating ListTiles
        if (data.isNotEmpty)
          ...data.entries.map((entry) {
            final percentage = (entry.value / totalOrders) * 100;
            return ListTile(
              leading: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: statusColors[entry.key] ?? Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(entry.key),
              trailing: Text(
                '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            );
          }).toList() else Center(child: Text('No order status data available.')),
      ],
    );
  }

  Widget _buildAnalyticsItem(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getTopSellingProducts() async {
    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('timestamp', isGreaterThanOrEqualTo: getStartDate(DateTime.now()))
          .get();

      Map<String, int> productCount = {};
      Map<String, double> productRevenue = {};

      for (var doc in ordersSnapshot.docs) {
        final items = doc.data()['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          try {
            final productName = item['name'] as String? ?? 'Unknown Product';
            final quantity = (item['quantity'] as num? ?? 0).toInt();
            final price = double.parse((item['price'] ?? '0').toString());

            productCount[productName] = (productCount[productName] ?? 0) + quantity;
            productRevenue[productName] = (productRevenue[productName] ?? 0.0) + (price * quantity);
          } catch (e) {
            print('Error processing product: $e');
            continue;
          }
        }
      }

      // Sort products by quantity sold
      var sortedProducts = productCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Take top 5 products
      final products = sortedProducts.take(5).map((e) => e.key).toList();
      final quantities = sortedProducts.take(5).map((e) => e.value.toDouble()).toList();
      final revenues = sortedProducts.take(5).map((e) => productRevenue[e.key] ?? 0.0).toList();

      return {
        'products': products,
        'quantities': quantities,
        'revenue': revenues,
      };
    } catch (e) {
      print('Error in _getTopSellingProducts: $e');
      return {
        'products': [],
        'quantities': [],
        'revenue': [],
      };
    }
  }

  Future<Map<String, dynamic>> _getCustomerAnalytics() async {
    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('timestamp', isGreaterThanOrEqualTo: getStartDate(DateTime.now()))
          .get();

      Map<String, int> customerOrders = {};
      Map<String, double> customerSpending = {};

      for (var doc in ordersSnapshot.docs) {
        try {
          final userId = doc.data()['userId'] as String? ?? '';
          final totalAmount = double.parse((doc.data()['totalAmount'] ?? '0').toString());

          customerOrders[userId] = (customerOrders[userId] ?? 0) + 1;
          customerSpending[userId] = (customerSpending[userId] ?? 0) + totalAmount;
        } catch (e) {
          print('Error processing customer: $e');
          continue;
        }
      }

      final totalCustomers = customerOrders.length;
      final averageOrderValue = totalCustomers > 0 
          ? customerSpending.values.fold(0.0, (a, b) => a + b) / totalCustomers 
          : 0.0;
      final repeatCustomers = customerOrders.values.where((count) => count > 1).length;

      return {
        'totalCustomers': totalCustomers,
        'averageOrderValue': averageOrderValue,
        'repeatCustomers': repeatCustomers,
      };
    } catch (e) {
      print('Error in _getCustomerAnalytics: $e');
      return {
        'totalCustomers': 0,
        'averageOrderValue': 0.0,
        'repeatCustomers': 0,
      };
    }
  }

  Future<Map<String, int>> _getOrderStatus() async {
    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('timestamp', isGreaterThanOrEqualTo: getStartDate(DateTime.now()))
          .get();

      Map<String, int> statusCount = {};

      for (var doc in ordersSnapshot.docs) {
        try {
          final status = doc.data()['status'] as String? ?? 'Unknown';
          statusCount[status] = (statusCount[status] ?? 0) + 1;
        } catch (e) {
          print('Error processing order status: $e');
          continue;
        }
      }

      return statusCount;
    } catch (e) {
      print('Error in _getOrderStatus: $e');
      return {};
    }
  }
}