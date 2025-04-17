import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_address_page.dart';

class AddressScreen extends StatefulWidget {
  @override
  _AddressScreenState createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  Stream<QuerySnapshot>? addressesStream;
  String _userName = "Guest";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      addressesStream =
          FirebaseFirestore.instance
              .collection('addresses')
              .where('userId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .snapshots();
      _getUserName();
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _getUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists && userDoc.data()?['name'] != null) {
          setState(() => _userName = userDoc.data()?['name']);
        } else if (user.displayName != null && user.displayName!.isNotEmpty) {
          setState(() => _userName = user.displayName!);
        }
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }

  void _navigateToAddAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAddressPage()),
    );
  }

  String _formatAddress(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    String address = '';
    if (data['street'] != null) address += data['street'];
    if (data['buildingNo'] != null) address += ' No:${data['buildingNo']}';
    if (data['doorNo'] != null) address += ' D${data['doorNo']}';
    if (data['apartment'] != null)
      address += ', ${data['apartment']} Apartment';
    if (data['neighborhood'] != null)
      address = '${data['neighborhood']}, $address';
    if (data['city'] != null) address += ', ${data['city']}';
    return address;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.transparent;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Addresses',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: bgColor,
          elevation: 0,
        ),
        backgroundColor: bgColor,
        body:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(color: Colors.red.shade300),
                )
                : RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _isLoading = true);
                    await Future.delayed(const Duration(seconds: 1));
                    setState(() => _isLoading = false);
                  },
                  color: Colors.red.shade300,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              margin: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                                boxShadow:
                                    isDark
                                        ? []
                                        : [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 5,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.red.shade700,
                                    radius: 24,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hello',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: textColor?.withOpacity(0.6),
                                          ),
                                        ),
                                        Text(
                                          _userName,
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _navigateToAddAddress,
                                icon: const Icon(Icons.add_location_alt, ),
                                label: const Text('Add New Address'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Text(
                                "Your Addresses",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      _buildAddressesList(),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildAddressesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: addressesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No addresses found.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = Theme.of(context).cardColor;
        final borderColor =
            isDark ? Colors.grey.shade700 : Colors.grey.shade200;
        final textColor = Theme.of(context).textTheme.bodyMedium?.color;

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.red.shade900
                                : Colors.red.shade50,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                isDark ? Colors.red.shade800 : Colors.red.shade100,
                            child: Icon(
                              data['addressType'] == 'Home'
                                  ? Icons.home
                                  : Icons.work,
                              color:
                                  isDark ? Colors.white : Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              data['label']?.toString().toUpperCase() ??
                                  'ADDRESS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color:
                                    isDark
                                        ? Colors.white
                                        : Colors.red.shade700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color:
                                  isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 18,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${data['firstName']} ${data['lastName']}',
                                style: TextStyle(color: textColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatAddress(doc),
                                  style: TextStyle(color: textColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 18,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${data['phone']}',
                                style: TextStyle(color: textColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        border: Border(top: BorderSide(color: borderColor)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () {},
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade300,
                            ),
                            label: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red.shade300),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {},
                            icon: Icon(
                              Icons.check_circle_outline,
                              color: Colors.green.shade600,
                            ),
                            label: Text(
                              'Set as Default',
                              style: TextStyle(color: Colors.green.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }, childCount: snapshot.data!.docs.length),
        );
      },
    );
  }
}
