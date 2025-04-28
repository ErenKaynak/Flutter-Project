import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show max;
import 'package:provider/provider.dart';
import 'package:engineering_project/pages/theme_notifier.dart';

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({super.key});

  @override
  State<AdminStatisticsPage> createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> {
  bool showMonthly = true;
  Map<String, double> data = {};
  Map<String, double> monthlySales = {};
  Map<String, double> monthlyStock = {};
  List<Map<String, dynamic>> productDetails = [];
  bool isLoading = true;
  int totalProductsSold = 0;

  // Add new state variables
  int totalUsers = 0;
  int totalOrders = 0;
  List<String> timeFrames = ['Weekly', 'Monthly', 'Yearly'];
  String selectedTimeFrame = 'Monthly';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([
        fetchMonthlySales(),
        fetchCategorySales(),
        fetchTopProducts(),
        calculateTotalProductsSold(),
        fetchTotalUsers(),
        fetchTotalOrders(),
      ]);
    } catch (e) {
      print('Error fetching data: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchMonthlySales() async {
    final now = DateTime.now();
    final monthsAgo = now.subtract(const Duration(days: 365));

    final ordersSnapshot =
        await FirebaseFirestore.instance
            .collection('orders')
            .where('orderDate', isGreaterThan: monthsAgo)
            .get();

    final Map<String, double> sales = {};
    final Map<String, double> stock = {};

    for (var doc in ordersSnapshot.docs) {
      final orderData = doc.data();
      final orderDate = (orderData['orderDate'] as Timestamp).toDate();
      final month =
          '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}';
      final items = orderData['items'] as List<dynamic>? ?? [];

      double monthlyTotal = 0.0;
      double monthlyQuantity = 0.0;

      for (var item in items) {
        final price = double.tryParse(item['price'].toString()) ?? 0.0;
        final quantity = item['quantity'] as int? ?? 0;

        monthlyTotal += price * quantity;
        monthlyQuantity += quantity;
      }

      sales[month] = (sales[month] ?? 0.0) + monthlyTotal;
      stock[month] = (stock[month] ?? 0.0) + monthlyQuantity;
    }

    setState(() {
      monthlySales = Map<String, double>.from(sales);
      monthlyStock = Map<String, double>.from(stock);
      data = showMonthly ? sales : data;
    });

    print('Monthly Sales: $monthlySales');
    print('Monthly Stock: $monthlyStock');
  }

  Future<void> fetchCategorySales() async {
    // First get products to create a map of product IDs to their categories
    final productsSnapshot =
        await FirebaseFirestore.instance.collection('products').get();

    final Map<String, Map<String, dynamic>> productsData = {};
    for (var doc in productsSnapshot.docs) {
      final data = doc.data();
      productsData[doc.id] = {
        'category': data['category'] as String? ?? 'Uncategorized',
        'price': data['price'] ?? 0.0,
      };
      print(
        'Product ID: ${doc.id}, Category: ${data['category']}, Price: ${data['price']}',
      );
    }

    final ordersSnapshot =
        await FirebaseFirestore.instance.collection('orders').get();

    final Map<String, double> categorySales = {};

    for (var doc in ordersSnapshot.docs) {
      final orderData = doc.data();
      final items = orderData['items'] as List<dynamic>? ?? [];

      for (var item in items) {
        final productId = item['productId'] as String?;
        if (productId == null) continue;

        final productInfo = productsData[productId];
        if (productInfo == null) {
          print('Warning: No product info found for ID: $productId');
          continue;
        }

        final category = productInfo['category'] as String;
        final price = double.tryParse(productInfo['price'].toString()) ?? 0.0;
        final quantity = item['quantity'] as int? ?? 0;

        // Sum up sales by category
        final saleAmount = price * quantity;
        categorySales[category] = (categorySales[category] ?? 0.0) + saleAmount;

        print(
          'Added sale - Category: $category, Amount: $saleAmount, Quantity: $quantity',
        );
      }
    }

    setState(() {
      data = Map<String, double>.from(categorySales);
    });

    print('Final Category Sales: $data');
  }

  Future<void> calculateTotalProductsSold() async {
    final ordersSnapshot =
        await FirebaseFirestore.instance.collection('orders').get();

    int totalSold = 0;
    for (var doc in ordersSnapshot.docs) {
      final items = doc.data()['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        final quantity = item['quantity'] as int? ?? 0;
        totalSold += quantity;
      }
    }

    print('Total products sold from orders: $totalSold');

    setState(() {
      totalProductsSold = totalSold;
    });
  }

  Future<void> fetchTopProducts() async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('products')
            .orderBy('sold', descending: true)
            .limit(10)
            .get();

    setState(() {
      productDetails =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            final sold = (data['sold'] ?? 0) as num;
            print(
              'Product: ${data['name']} - Sold: $sold - Category: ${data['category']}',
            );

            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unnamed Product',
              'price': data['price']?.toString() ?? '0',
              'sold': sold,
              'stock': data['stock'] ?? 0,
              'image': data['imagePath'] ?? 'lib/assets/Images/placeholder.png',
              'category': data['category'] ?? 'Uncategorized',
            };
          }).toList();
    });
  }

  Future<void> fetchTotalUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      totalUsers = snapshot.docs.length;
    });
  }

  Future<void> fetchTotalOrders() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('orders').get();
    setState(() {
      totalOrders = snapshot.docs.length;
    });
  }

  Widget _buildBarChart() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isBlackMode = themeNotifier.isBlackMode;
    final months = monthlySales.keys.toList()..sort();

    if (months.isEmpty) {
      return Center(
        child: Text(
          'No data available for the selected period',
          style: TextStyle(
            fontSize: 16,
            color: isBlackMode ? Colors.white : null,
          ),
        ),
      );
    }

    final maxValue = [
      monthlyStock.values.fold(0.0, (a, b) => max(a, b)),
      monthlySales.values.fold(0.0, (a, b) => max(a, b)),
    ].reduce(max);

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = months[group.x.toInt()];
                final value = rod.toY;
                final label = rodIndex == 0 ? 'Items Sold' : 'Sales';
                return BarTooltipItem(
                  '$label\n${rodIndex == 0 ? value.toInt() : '₺${value.toStringAsFixed(2)}'}',
                  TextStyle(color: isBlackMode ? Colors.black : Colors.white),
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
                  if (value < 0 || value >= months.length)
                    return const Text('');
                  final month = months[value.toInt()];
                  // Convert numeric month to abbreviated name
                  final monthName = _getMonthName(
                    int.parse(month.split('-')[1]),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      monthName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isBlackMode ? Colors.white : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '₺${value.toInt()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isBlackMode ? Colors.white : null,
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: isBlackMode ? Colors.grey.shade700 : Colors.grey,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            months.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: monthlyStock[months[index]] ?? 0,
                  color:
                      isBlackMode
                          ? Colors.grey.shade500
                          : Colors.red.withOpacity(0.7),
                  width: 12,
                ),
                BarChartRodData(
                  toY: monthlySales[months[index]] ?? 0,
                  color: Colors.green.withOpacity(0.7),
                  width: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to convert month number to abbreviated name
  String _getMonthName(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (month >= 1 && month <= 12) {
      return monthNames[month - 1];
    }
    return '';
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.8, // Increased from 1.5 to give more height
      children: [
        _buildStatsCard(
          'Total Sales',
          '₺${_calculateTotalSales().toStringAsFixed(2)}',
          Icons.attach_money_rounded,
          LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade700],
          ),
        ),
        _buildStatsCard(
          'Products Sold',
          totalProductsSold.toString(),
          Icons.inventory_2_rounded,
          LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade700]),
        ),
        _buildStatsCard(
          'Total Users',
          totalUsers.toString(),
          Icons.people_rounded,
          LinearGradient(
            colors: [Colors.orange.shade400, Colors.orange.shade700],
          ),
        ),
        _buildStatsCard(
          'Total Orders',
          totalOrders.toString(),
          Icons.shopping_bag_rounded,
          LinearGradient(
            colors: [Colors.purple.shade400, Colors.purple.shade700],
          ),
        ),
      ],
    );
  }

  double _calculateTotalSales() {
    return monthlySales.values.fold(0.0, (sum, value) => sum + value);
  }

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    LinearGradient gradient,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.last.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              icon,
              size: 80, // Reduced from 100
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0), // Reduced from 16
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(6), // Reduced from 8
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ), // Reduced from 24
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13, // Reduced from 14
                      ),
                    ),
                    SizedBox(height: 2), // Reduced from 4
                    FittedBox(
                      // Added FittedBox to prevent text overflow
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20, // Reduced from 24
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isBlackMode = themeNotifier.isBlackMode;

    return Container(
      margin: EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: isBlackMode ? Colors.black : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                isBlackMode
                    ? Colors.grey.shade900
                    : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Sales Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isBlackMode ? Colors.white : null,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color:
                          isBlackMode
                              ? Colors.grey.shade800
                              : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          timeFrames.map((frame) {
                            final isSelected = selectedTimeFrame == frame;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  selectedTimeFrame = frame;
                                  fetchData();
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? (isBlackMode
                                              ? Colors.grey.shade500
                                              : Colors.red.shade700)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  frame,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : (isBlackMode
                                                ? Colors.white
                                                : Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.color),
                                    fontSize: 14,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            SizedBox(height: 300, child: _buildBarChart()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isBlackMode = themeNotifier.isBlackMode;
    final isDark =
        Theme.of(context).brightness == Brightness.dark && !isBlackMode;

    return Scaffold(
      backgroundColor:
          isBlackMode
              ? Colors.black
              : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor:
            isBlackMode
                ? Colors.black
                : isDark
                ? Colors.black
                : Colors.red.shade700,
        elevation: isDark ? 0 : 2,
        foregroundColor: Colors.white,
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: isBlackMode ? Colors.grey.shade500 : Colors.red,
                ),
              )
              : RefreshIndicator(
                onRefresh: fetchData,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewCards(),
                        SizedBox(height: 24),
                        _buildSalesChart(),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
