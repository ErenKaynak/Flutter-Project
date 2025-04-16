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
  String _userName = "Guest"; // Default user name
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize the stream to fetch addresses
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      addressesStream = FirebaseFirestore.instance
          .collection('addresses')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots();

      _getUserName(); // Get current user name
    }

    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Fetch current user name from Firestore
  Future<void> _getUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Try to get user profile from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data()?['name'] != null) {
          if (mounted) {
            setState(() {
              _userName = userDoc.data()?['name'];
            });
          }
        } else if (user.displayName != null && user.displayName!.isNotEmpty) {
          // Fallback to Firebase Auth display name
          if (mounted) {
            setState(() {
              _userName = user.displayName!;
            });
          }
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
    // No need to manually update state as the stream will handle it
  }

  String _formatAddress(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    String formattedAddress = '';

    if (data['street'] != null && data['street'].toString().isNotEmpty) {
      formattedAddress += data['street'];
    }

    if (data['buildingNo'] != null && data['buildingNo'].toString().isNotEmpty) {
      formattedAddress += ' No:${data['buildingNo']}';
    }

    if (data['doorNo'] != null && data['doorNo'].toString().isNotEmpty) {
      formattedAddress += ' D${data['doorNo']}';
    }

    if (data['apartment'] != null && data['apartment'].toString().isNotEmpty) {
      formattedAddress += ', ${data['apartment']} Apartment';
    }

    if (data['neighborhood'] != null && data['neighborhood'].toString().isNotEmpty) {
      formattedAddress = '${data['neighborhood']}, ' + formattedAddress;
    }

    if (data['city'] != null && data['city'].toString().isNotEmpty) {
      formattedAddress += ', ${data['city']}';
    }

    return formattedAddress;
  }

  // Method to handle editing address
  void _editAddress(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAddressPage(
          isEditing: true,
          addressData: data,
          addressId: doc.id,
        ),
      ),
    );
  }

  // Method to handle address deletion
  Future<void> _deleteAddress(String addressId) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show confirmation dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Delete Address',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this address?',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('addresses')
            .doc(addressId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting address: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // Method to set address as default
  Future<void> _setAsDefault(String addressId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Start a batch write
      final batch = FirebaseFirestore.instance.batch();

      // First, remove isDefault from all addresses
      final addresses = await FirebaseFirestore.instance
          .collection('addresses')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in addresses.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // Set the selected address as default
      batch.update(
        FirebaseFirestore.instance.collection('addresses').doc(addressId),
        {'isDefault': true},
      );

      // Commit the batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Default address updated'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating default address: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'My Addresses',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
            : RefreshIndicator(
                onRefresh: () async {
                  setState(() => _isLoading = true);
                  await Future.delayed(Duration(seconds: 1));
                  setState(() => _isLoading = false);
                },
                color: Theme.of(context).primaryColor,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome section
                          Container(
                            padding: EdgeInsets.all(16.0),
                            margin: EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [Colors.red.shade900, Colors.grey.shade900]
                                    : [Colors.red.shade300, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isDark
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
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.red.shade900 : Colors.red.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    size: 36,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Hello",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDark ? Colors.grey[400] : Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        _userName,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Information container
                          Container(
                            padding: EdgeInsets.all(16.0),
                            margin: EdgeInsets.symmetric(horizontal: 10.0),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.blue.shade900.withOpacity(0.2)
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 3,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Changes here do not affect current orders.',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.blue.shade300
                                            : Colors.blue.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // Add new address button
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 10.0),
                            child: ElevatedButton.icon(
                              onPressed: _navigateToAddAddress,
                              icon: Icon(Icons.add_location_alt, size: 24),
                              label: Text(
                                'Add New Address',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.fromHeight(54),
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 20),

                          // Addresses header
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              "Your Addresses",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),

                          SizedBox(height: 10),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: addressesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Container(
              height: 200,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.red.shade800 : Colors.red.shade200,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48,
                        color: isDark ? Colors.red.shade300 : Colors.red.shade700),
                    SizedBox(height: 16),
                    Text(
                      'Error loading addresses',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: isDark ? Colors.red.shade300 : Colors.red.shade700),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              height: 200,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900.withOpacity(0.2) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off,
                        size: 48, color: isDark ? Colors.grey.shade400 : Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No addresses saved yet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.grey.shade400 : Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add your first address!',
                      style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Container(
                margin: EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: data['addressType'] == 'Home'
                                ? (isDark
                                    ? Colors.blue.shade900.withOpacity(0.2)
                                    : Colors.blue.shade50)
                                : (isDark
                                    ? Colors.orange.shade900.withOpacity(0.2)
                                    : Colors.orange.shade50),
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: data['addressType'] == 'Home'
                                      ? (isDark
                                          ? Colors.blue.shade900
                                          : Colors.blue.shade100)
                                      : (isDark
                                          ? Colors.orange.shade900
                                          : Colors.orange.shade100),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  data['addressType'] == 'Home'
                                      ? Icons.home
                                      : Icons.work,
                                  color: data['addressType'] == 'Home'
                                      ? (isDark
                                          ? Colors.blue.shade300
                                          : Colors.blue.shade700)
                                      : (isDark
                                          ? Colors.orange.shade300
                                          : Colors.orange.shade700),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  data['label'] != null &&
                                          data['label'].toString().isNotEmpty
                                      ? data['label'].toString().toUpperCase()
                                      : data['addressType'].toString().toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: data['addressType'] == 'Home'
                                        ? (isDark
                                            ? Colors.blue.shade300
                                            : Colors.blue.shade700)
                                        : (isDark
                                            ? Colors.orange.shade300
                                            : Colors.orange.shade700),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                onPressed: () => _editAddress(doc),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 18,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${data['firstName']} ${data['lastName']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 18,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _formatAddress(doc),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 18,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${data['phone']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade900.withOpacity(0.2)
                                : Colors.grey.shade50,
                            borderRadius:
                                BorderRadius.vertical(bottom: Radius.circular(12)),
                            border: Border(
                              top: BorderSide(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () => _deleteAddress(doc.id),
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.red.shade300),
                                label: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red.shade300),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _setAsDefault(doc.id),
                                icon: Icon(
                                  Icons.check_circle_outline,
                                  color: data['isDefault'] == true
                                      ? Colors.green
                                      : Colors.green.shade600,
                                ),
                                label: Text(
                                  data['isDefault'] == true
                                      ? 'Default'
                                      : 'Set as Default',
                                  style: TextStyle(
                                    color: data['isDefault'] == true
                                        ? Colors.green
                                        : Colors.green.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            childCount: snapshot.data!.docs.length,
          ),
        );
      },
    );
  }
}