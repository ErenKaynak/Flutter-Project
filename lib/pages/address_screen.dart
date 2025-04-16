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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My Addresses',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: _isLoading 
            ? Center(child: CircularProgressIndicator(color: Colors.red.shade300))
            : RefreshIndicator(
                onRefresh: () async {
                  // Pull to refresh functionality
                  setState(() {
                    _isLoading = true;
                  });
                  await Future.delayed(Duration(seconds: 1));
                  setState(() {
                    _isLoading = false;
                  });
                },
                color: Colors.red.shade300,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome section with user name and person icon
                          Container(
                            padding: EdgeInsets.all(16.0),
                            margin: EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red.shade300, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
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
                                    color: Colors.red.shade300,
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
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        _userName,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
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
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Changes here do not affect current orders.',
                                    style: TextStyle(color: Colors.blue.shade700),
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
                                backgroundColor: Colors.red.shade300,
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
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                    
                    // Addresses list
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
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Container(
              height: 200,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    SizedBox(height: 16),
                    Text(
                      'Error loading addresses',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
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
                child: CircularProgressIndicator(color: Colors.red.shade300),
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
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No addresses saved yet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add your first address!',
                      style: TextStyle(color: Colors.grey[600]),
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
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: data['addressType'] == 'Home' 
                                ? Colors.blue.shade50 
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: data['addressType'] == 'Home' 
                                      ? Colors.blue.shade100 
                                      : Colors.orange.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  data['addressType'] == 'Home' ? Icons.home : Icons.work,
                                  color: data['addressType'] == 'Home' 
                                      ? Colors.blue.shade700 
                                      : Colors.orange.shade700,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  data['label'] != null && data['label'].toString().isNotEmpty
                                      ? data['label'].toString().toUpperCase()
                                      : data['addressType'].toString().toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: data['addressType'] == 'Home' 
                                        ? Colors.blue.shade700 
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  // TO DO: Implement edit functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Edit feature coming soon'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      backgroundColor: Colors.red.shade300,
                                    ),
                                  );
                                },
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
                                    color: Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${data['firstName']} ${data['lastName']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
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
                                    color: Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _formatAddress(doc),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
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
                                    color: Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${data['phone']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade800,
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
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  // TO DO: Implement delete functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Delete feature coming soon'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      backgroundColor: Colors.red.shade300,
                                    ),
                                  );
                                },
                                icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                                label: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red.shade300),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  // TO DO: Implement set as default functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Set as default feature coming soon'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      backgroundColor: Colors.red.shade300,
                                    ),
                                  );
                                },
                                icon: Icon(Icons.check_circle_outline, color: Colors.green.shade600),
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