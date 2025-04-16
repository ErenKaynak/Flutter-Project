import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAddressPage extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? addressData;
  final String? addressId;

  const AddAddressPage({
    Key? key,
    this.isEditing = false,
    this.addressData,
    this.addressId,
  }) : super(key: key);

  @override
  _AddAddressPageState createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _buildingNoController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _doorNoController = TextEditingController();
  final TextEditingController _addressLabelController = TextEditingController();

  String _selectedAddressType = 'Home';
  String _selectedCity = '';

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
  void initState() {
    super.initState();
    if (widget.isEditing && widget.addressData != null) {
      // Populate form fields with existing data
      _firstNameController.text = widget.addressData!['firstName'] ?? '';
      _lastNameController.text = widget.addressData!['lastName'] ?? '';
      _phoneController.text = widget.addressData!['phone'] ?? '';
      _streetController.text = widget.addressData!['street'] ?? '';
      _neighborhoodController.text = widget.addressData!['neighborhood'] ?? '';
      _buildingNoController.text = widget.addressData!['buildingNo'] ?? '';
      _apartmentController.text = widget.addressData!['apartment'] ?? '';
      _floorController.text = widget.addressData!['floor'] ?? '';
      _doorNoController.text = widget.addressData!['doorNo'] ?? '';
      _addressLabelController.text = widget.addressData!['label'] ?? '';
      _selectedCity = widget.addressData!['city'] ?? '';

      setState(() {
        _selectedAddressType = widget.addressData!['addressType'] ?? 'Home';
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes when the page is disposed
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _neighborhoodController.dispose();
    _buildingNoController.dispose();
    _apartmentController.dispose();
    _floorController.dispose();
    _doorNoController.dispose();
    _addressLabelController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          widget.isEditing ? 'Edit Address' : 'Add New Address',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: isDark ? 0 : 2,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.grey.shade900, Colors.black]
                : [Colors.red.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              // Header Section with Icon
              Container(
                padding: EdgeInsets.all(16.0),
                margin: EdgeInsets.all(16.0),
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
                        widget.isEditing ? Icons.edit_location : Icons.add_location,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEditing ? "Update Address" : "New Address",
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.grey[400] : Colors.black54,
                            ),
                          ),
                          Text(
                            widget.isEditing
                                ? "Edit your delivery location"
                                : "Add your delivery location",
                            style: TextStyle(
                              fontSize: 20,
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

              // Form Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
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
                                    controller: _firstNameController,
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
                                    controller: _lastNameController,
                                    focusNode: _lastNameFocus,
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
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              keyboardType: TextInputType.phone,
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
                              controller: _streetController,
                              focusNode: _streetFocus,
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
                              controller: _neighborhoodController,
                              focusNode: _neighborhoodFocus,
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
                                    controller: _buildingNoController,
                                    focusNode: _buildingNoFocus,
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
                                    controller: _apartmentController,
                                    focusNode: _apartmentFocus,
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
                                    controller: _floorController,
                                    focusNode: _floorFocus,
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
                                    controller: _doorNoController,
                                    focusNode: _doorNoFocus,
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
                              controller: _addressLabelController,
                              focusNode: _addressLabelFocus,
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
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 24),
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
                            widget.isEditing ? 'Update Address' : 'Save Address',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.red.shade900 : Colors.red.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: Colors.grey.shade700, width: 1)
            : null,
        boxShadow: isDark
            ? []
            : [
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
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    Function(String)? onFieldSubmitted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.red.shade700 : Colors.red.shade300,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  Widget _buildAddressTypeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: Row(
        children: [
          _buildAddressTypeOption('Home', Icons.home),
          Container(
            width: 1,
            height: 90,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
          _buildAddressTypeOption('Work', Icons.work),
        ],
      ),
    );
  }

  Widget _buildAddressTypeOption(String type, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedAddressType == type;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedAddressType = type),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50)
                : (isDark ? Colors.grey.shade800 : Colors.white),
            borderRadius: BorderRadius.horizontal(
              left: type == 'Home' ? Radius.circular(12) : Radius.zero,
              right: type == 'Work' ? Radius.circular(12) : Radius.zero,
            ),
            border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.red.shade700 : Colors.red.shade300)
                  : Colors.transparent,
              width: isSelected ? 2 : 0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? (isDark ? Colors.red.shade400 : Colors.red.shade700)
                    : (isDark ? Colors.grey.shade400 : Colors.grey),
                size: 28,
              ),
              SizedBox(height: 8),
              Text(
                type,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? (isDark ? Colors.red.shade400 : Colors.red.shade700)
                      : (isDark ? Colors.grey.shade300 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'City',
        labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.red.shade700 : Colors.red.shade300,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      value: _selectedCity.isEmpty ? null : _selectedCity,
      hint: Text(
        'Select City',
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
      icon: Icon(Icons.arrow_drop_down,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Please select a city';
        }
        return null;
      },
      items: ['Istanbul', 'Ankara', 'Izmir', 'Antalya', 'Bursa'].map((String city) {
        return DropdownMenuItem<String>(
          value: city,
          child: Text(
            city,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedCity = val!),
    );
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      try {
        final addressData = {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'phone': _phoneController.text,
          'addressType': _selectedAddressType,
          'street': _streetController.text,
          'neighborhood': _neighborhoodController.text,
          'buildingNo': _buildingNoController.text,
          'apartment': _apartmentController.text,
          'floor': _floorController.text,
          'doorNo': _doorNoController.text,
          'city': _selectedCity,
          'label': _addressLabelController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (widget.isEditing) {
          // Update existing address
          await FirebaseFirestore.instance
              .collection('addresses')
              .doc(widget.addressId)
              .update(addressData);
        } else {
          // Create new address
          addressData['createdAt'] = FieldValue.serverTimestamp();
          addressData['userId'] = FirebaseAuth.instance.currentUser?.uid ?? '';
          await FirebaseFirestore.instance
              .collection('addresses')
              .add(addressData);
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving address: $e')),
        );
      }
    } else {
      // Form validation failed
      // Auto-scroll to the first error
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }
}
