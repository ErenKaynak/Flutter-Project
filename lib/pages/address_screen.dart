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
    return Scaffold(
      appBar: AppBar(title: Text('My Addresses')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Changes here do not affect current orders.',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _navigateToAddAddress,
              icon: Icon(Icons.add),
              label: Text('Add New Address'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(50),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: addressesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading addresses: ${snapshot.error}'),
                    );
                  }
                  
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text('No addresses saved yet. Add your first address!'),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            data['addressType'] == 'Home' ? Icons.home : Icons.work,
                          ),
                          title: Text(
                            data['label'] != null && data['label'].toString().isNotEmpty
                                ? data['label'].toString().toUpperCase()
                                : data['addressType'].toString().toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${data['firstName']} ${data['lastName']}'),
                              Text(_formatAddress(doc)),
                              Text('Phone: ${data['phone']}'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              // TO DO: Implement edit functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Edit feature coming soon')),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}