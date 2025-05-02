import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
  
  // Chart data
  Map<String, double> revenueData = {};
  Map<String, int> productData = {};

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

      // First, get ALL orders for total statistics
      final allOrdersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .get();
      
      // Calculate total products from ALL orders
      int totalProductCount = 0;
      double totalRevenueAmount = 0;
      
      // Process all orders for total counts
      for (var doc in allOrdersSnapshot.docs) {
        final data = doc.data();
        final items = data['items'] as List<dynamic>? ?? [];
        
        for (var item in items) {
          try {
            final quantity = (item['quantity'] as num? ?? 0).toInt();
            final price = double.parse((item['price'] ?? '0').toString());
            
            totalProductCount += quantity;
            totalRevenueAmount += price * quantity;
          } catch (e) {
            print('Error processing total item: $e');
            continue;
          }
        }
      }

      // Get filtered orders for the period chart
      final filteredOrdersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: startDate)
          .orderBy('orderDate', descending: true)
          .get();

      Map<String, double> periodRevenue = {};
      Map<String, int> periodProducts = {};

      // Process filtered orders for the chart
      for (var doc in filteredOrdersSnapshot.docs) {
        final data = doc.data();
        final Timestamp? orderDateStamp = data['orderDate'] as Timestamp?;
        
        if (orderDateStamp == null) continue;

        final orderDate = orderDateStamp.toDate();
        final items = data['items'] as List<dynamic>? ?? [];
        String periodKey = getPeriodKey(orderDate);
        
        for (var item in items) {
          try {
            final quantity = (item['quantity'] as num? ?? 0).toInt();
            final price = double.parse((item['price'] ?? '0').toString());
            
            periodRevenue[periodKey] = (periodRevenue[periodKey] ?? 0) + (price * quantity);
            periodProducts[periodKey] = (periodProducts[periodKey] ?? 0) + quantity;
          } catch (e) {
            print('Error processing period item: $e');
            continue;
          }
        }
      }

      // Fetch users count
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      print('Debug Statistics:');
      print('Total Products Sold: $totalProductCount');
      print('Total Revenue: $totalRevenueAmount');
      print('Total Orders: ${allOrdersSnapshot.size}');
      print('Period Products: $periodProducts');

      setState(() {
        totalRevenue = totalRevenueAmount;
        totalProducts = totalProductCount; // This should now show the correct total
        totalOrders = allOrdersSnapshot.size;
        totalUsers = usersSnapshot.size;
        revenueData = Map<String, double>.from(periodRevenue);
        productData = Map<String, int>.from(periodProducts);
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

  String getPeriodKey(DateTime date) {
    switch (selectedTimeFrame) {
      case 'Weekly':
        return DateFormat('MM/dd').format(date);
      case 'Monthly':
        return DateFormat('MM/dd').format(date);
      case 'Yearly':
        return DateFormat('MMM').format(date);
      default:
        return DateFormat('MM/dd').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Statistics'),
        backgroundColor: Colors.red[700],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeFrameSelector(),
                    const SizedBox(height: 20),
                    _buildStatisticsCards(),
                    const SizedBox(height: 20),
                    _buildChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimeFrameSelector() {
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
            selectedColor: Colors.red[700],
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatisticsCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total Revenue',
          '₺${totalRevenue.toStringAsFixed(2)}',
          Icons.monetization_on,
          Colors.green,
        ),
        _buildStatCard(
          'Products Sold',
          totalProducts.toString(),
          Icons.inventory,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Users',
          totalUsers.toString(),
          Icons.people,
          Colors.orange,
        ),
        _buildStatCard(
          'Total Orders',
          totalOrders.toString(),
          Icons.shopping_cart,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
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
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: revenueData.values.isEmpty ? 100 : 
                revenueData.values.reduce((a, b) => a > b ? a : b) * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              //tooltipBackground: Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '₺${rod.toY.toStringAsFixed(2)}\n'
                  '${productData.values.elementAt(groupIndex)} products',
                  const TextStyle(color: Colors.white),
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
                  if (value < 0 || value >= revenueData.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      revenueData.keys.elementAt(value.toInt()),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: revenueData.entries.map((entry) {
            return BarChartGroupData(
              x: revenueData.keys.toList().indexOf(entry.key),
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: Colors.red[700],
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}