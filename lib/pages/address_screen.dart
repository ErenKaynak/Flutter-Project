import 'package:flutter/material.dart';
import 'add_address_page.dart'; // ✅ Bu dosyayı eklemeyi unutma

class AddressScreen extends StatefulWidget {
  @override
  _AddressScreenState createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List<String> addresses = ['Refah Street No:16 D2, Hanımeli Apartment'];

  void _navigateToAddAddress() async {
    final newAddress = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAddressPage()),
    );

    if (newAddress != null && newAddress is String) {
      setState(() {
        addresses.add(newAddress);
      });
    }
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
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.home),
                      title: Text('HOME'),
                      subtitle: Text(addresses[index]),
                      trailing: Icon(Icons.edit),
                    ),
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
