import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAddressPage extends StatefulWidget {
  @override
  _AddAddressPageState createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

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

  // Focus nodes to manage keyboard focus
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _streetFocus = FocusNode();
  final FocusNode _neighborhoodFocus = FocusNode();
  final FocusNode _buildingNoFocus = FocusNode();
  final FocusNode _apartmentFocus = FocusNode();
  final FocusNode _floorFocus = FocusNode();
  final FocusNode _doorNoFocus = FocusNode();
  final FocusNode _addressLabelFocus = FocusNode();

  @override
  void dispose() {
    // Dispose focus nodes when the page is disposed
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _streetFocus.dispose();
    _neighborhoodFocus.dispose();
    _buildingNoFocus.dispose();
    _apartmentFocus.dispose();
    _floorFocus.dispose();
    _doorNoFocus.dispose();
    _addressLabelFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.red.shade700,
        title: Text('Add New Address'),
        leading: BackButton(),
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.red.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Recipient Info', Icons.person),
                  SizedBox(height: 15),
                  _buildInputCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'First Name',
                                onChanged: (val) => firstName = val,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please enter first name';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_lastNameFocus);
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: 'Last Name',
                                focusNode: _lastNameFocus,
                                onChanged: (val) => lastName = val,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please enter last name';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_phoneFocus);
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          label: 'Phone Number',
                          focusNode: _phoneFocus,
                          keyboardType: TextInputType.phone,
                          onChanged: (val) => phone = val,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter phone number';
                            }
                            // Basic phone validation
                            if (val.length < 10) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_streetFocus);
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 25),
                  _buildSectionHeader('Address Type', Icons.location_on),
                  SizedBox(height: 15),
                  _buildAddressTypeSelector(),

                  SizedBox(height: 25),
                  _buildSectionHeader('Address Details', Icons.home),
                  SizedBox(height: 15),
                  _buildInputCard(
                    child: Column(
                      children: [
                        _buildTextField(
                          label: 'Street / Avenue',
                          focusNode: _streetFocus,
                          onChanged: (val) => street = val,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter street name';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_neighborhoodFocus);
                          },
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          label: 'Neighborhood',
                          focusNode: _neighborhoodFocus,
                          onChanged: (val) => neighborhood = val,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter neighborhood';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_buildingNoFocus);
                          },
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Building No',
                                focusNode: _buildingNoFocus,
                                onChanged: (val) => buildingNo = val,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_apartmentFocus);
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: 'Apartment Name',
                                focusNode: _apartmentFocus,
                                onChanged: (val) => apartment = val,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_floorFocus);
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Floor No',
                                focusNode: _floorFocus,
                                onChanged: (val) => floor = val,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_doorNoFocus);
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: 'Door No',
                                focusNode: _doorNoFocus,
                                onChanged: (val) => doorNo = val,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildCityDropdown(),
                        SizedBox(height: 16),
                        _buildTextField(
                          label: 'Address Label',
                          hintText: 'Example: Home, Work, etc.',
                          focusNode: _addressLabelFocus,
                          onChanged: (val) => addressLabel = val,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter an address label';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required String label,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  Widget _buildAddressTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => addressType = 'Home'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color:
                      addressType == 'Home' ? Colors.red.shade50 : Colors.white,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  border: Border.all(
                    color:
                        addressType == 'Home'
                            ? Colors.red.shade300
                            : Colors.transparent,
                    width: addressType == 'Home' ? 2 : 0,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.home,
                      color:
                          addressType == 'Home'
                              ? Colors.red.shade700
                              : Colors.grey,
                      size: 28,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Home',
                      style: TextStyle(
                        fontWeight:
                            addressType == 'Home'
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color:
                            addressType == 'Home'
                                ? Colors.red.shade700
                                : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 90, color: Colors.grey.shade200),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => addressType = 'Work'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color:
                      addressType == 'Work' ? Colors.red.shade50 : Colors.white,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(12),
                  ),
                  border: Border.all(
                    color:
                        addressType == 'Work'
                            ? Colors.red.shade300
                            : Colors.transparent,
                    width: addressType == 'Work' ? 2 : 0,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.work,
                      color:
                          addressType == 'Work'
                              ? Colors.red.shade700
                              : Colors.grey,
                      size: 28,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Work',
                      style: TextStyle(
                        fontWeight:
                            addressType == 'Work'
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color:
                            addressType == 'Work'
                                ? Colors.red.shade700
                                : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'City',
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      value: city.isEmpty ? null : city,
      hint: Text('Select City'),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Please select a city';
        }
        return null;
      },
      items:
          ['Istanbul', 'Ankara', 'Izmir', 'Antalya', 'Bursa'].map((
            String city,
          ) {
            return DropdownMenuItem<String>(value: city, child: Text(city));
          }).toList(),
      onChanged: (val) => setState(() => city = val!),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade700],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade300.withOpacity(0.5),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveAddress,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Save Address',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    // First validate all fields
    if (_formKey.currentState!.validate()) {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        print("✅ UID: $uid");

        if (uid == null) {
          _showErrorSnackBar('User not logged in.');
          return;
        }

        // Show loading indicator
        _showLoadingDialog();

        await FirebaseFirestore.instance.collection('addresses').add({
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

        // Dismiss loading dialog
        Navigator.pop(context);

        _showSuccessSnackBar('Address saved successfully');

        // Return to previous screen
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      } catch (e) {
        // Dismiss loading dialog if it's showing
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _showErrorSnackBar('Error saving address: $e');
      }
    } else {
      // Form validation failed
      // Auto-scroll to the first error
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      _showErrorSnackBar('Please fill all required fields');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                SizedBox(height: 16),
                Text(
                  'Saving address...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
