import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAddressPage extends StatefulWidget {
  @override
  _AddAddressPageState createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();

  String firstName = '';
  String lastName = '';
  String phone = '';
  String addressType = 'Home';
  String street = '';
  String neighborhood = '';
  String buildingNo = '';
  String apartment = '';
  String floor = '';
  String doorNo = '';
  String city = '';
  String addressLabel = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Address'), leading: BackButton()),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recipient Info',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'First Name'),
                      onChanged: (val) => firstName = val,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Last Name'),
                      onChanged: (val) => lastName = val,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                onChanged: (val) => phone = val,
              ),
              SizedBox(height: 20),
              Text(
                'Address Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'Home',
                      groupValue: addressType,
                      title: Text('Home'),
                      onChanged: (val) => setState(() => addressType = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'Work',
                      groupValue: addressType,
                      title: Text('Work'),
                      onChanged: (val) => setState(() => addressType = val!),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Address Details',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Street / Avenue'),
                onChanged: (val) => street = val,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Neighborhood'),
                onChanged: (val) => neighborhood = val,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Building No'),
                onChanged: (val) => buildingNo = val,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Apartment Name'),
                onChanged: (val) => apartment = val,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Floor No'),
                onChanged: (val) => floor = val,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Door No'),
                onChanged: (val) => doorNo = val,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'City'),
                items:
                    ['Istanbul', 'Ankara', 'Izmir'].map((String city) {
                      return DropdownMenuItem<String>(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),
                onChanged: (val) => city = val!,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Address Label',
                  hintText: 'Example: Home, Work, etc.',
                ),
                onChanged: (val) => addressLabel = val,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      print("✅ UID: \$uid");

                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('User not logged in.')),
                        );
                        return;
                      }

                      await FirebaseFirestore.instance
                          .collection('addresses')
                          .add({
                            'userId': uid,
                            'firstName': firstName,
                            'lastName': lastName,
                            'phone': phone,
                            'addressType': addressType,
                            'street': street,
                            'neighborhood': neighborhood,
                            'buildingNo': buildingNo,
                            'apartment': apartment,
                            'floor': floor,
                            'doorNo': doorNo,
                            'city': city,
                            'label': addressLabel,
                            'createdAt': Timestamp.now(),
                          });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Address saved successfully')),
                      );

                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving address: \$e')),
                      );
                    }
                  }
                },
                child: Text('Save Address'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
