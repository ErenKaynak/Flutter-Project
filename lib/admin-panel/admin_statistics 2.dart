import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
}