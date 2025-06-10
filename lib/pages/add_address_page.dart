import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'theme_notifier.dart';

class AddAddressPage extends StatefulWidget {
  final DocumentSnapshot? addressToEdit;

  const AddAddressPage({Key? key, this.addressToEdit}) : super(key: key);

  @override
  _AddAddressPageState createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _apiKey = 'AIzaSyDFYH2YvsVidC2ssabxM7ixKAMj6umhhK8';

  // Add TextEditingControllers
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
  final TextEditingController _searchController = TextEditingController();

  String addressType = 'Home';
  String country = '';
  String state = '';
  String city = '';
  String postalCode = '';
  double? latitude;
  double? longitude;
  String? addressId;
  bool isLoadingCountries = false;
  bool isLoadingCities = false;
  List<String> cities = [];

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

  // Map of countries and their major cities
  final Map<String, List<String>> countryCities = {
    'Turkey': ['Istanbul', 'Ankara', 'Izmir', 'Antalya', 'Bursa', 'Adana', 'Gaziantep', 'Konya', 'Mersin', 'Diyarbakir'],
    'United States': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose'],
    'United Kingdom': ['London', 'Manchester', 'Birmingham', 'Leeds', 'Glasgow', 'Liverpool', 'Newcastle', 'Sheffield', 'Bristol', 'Edinburgh'],
    'Germany': ['Berlin', 'Hamburg', 'Munich', 'Cologne', 'Frankfurt', 'Stuttgart', 'Düsseldorf', 'Leipzig', 'Dortmund', 'Essen'],
    'France': ['Paris', 'Marseille', 'Lyon', 'Toulouse', 'Nice', 'Nantes', 'Strasbourg', 'Montpellier', 'Bordeaux', 'Lille'],
    'Italy': ['Rome', 'Milan', 'Naples', 'Turin', 'Palermo', 'Genoa', 'Bologna', 'Florence', 'Bari', 'Catania'],
    'Spain': ['Madrid', 'Barcelona', 'Valencia', 'Seville', 'Zaragoza', 'Málaga', 'Murcia', 'Palma', 'Las Palmas', 'Bilbao'],
    'Canada': ['Toronto', 'Montreal', 'Vancouver', 'Calgary', 'Edmonton', 'Ottawa', 'Winnipeg', 'Quebec City', 'Hamilton', 'Kitchener'],
    'Australia': ['Sydney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaide', 'Gold Coast', 'Newcastle', 'Canberra', 'Wollongong', 'Hobart'],
    'Japan': ['Tokyo', 'Yokohama', 'Osaka', 'Nagoya', 'Sapporo', 'Fukuoka', 'Kobe', 'Kyoto', 'Kawasaki', 'Saitama'],
  };

  // Map of local country names to English names
  final Map<String, String> countryNameMap = {
    'Türkiye': 'Turkey',
    'United States of America': 'United States',
    'United Kingdom of Great Britain and Northern Ireland': 'United Kingdom',
    'Deutschland': 'Germany',
    'République française': 'France',
    'Repubblica Italiana': 'Italy',
    'Reino de España': 'Spain',
    'Canada': 'Canada',
    'Commonwealth of Australia': 'Australia',
    '日本': 'Japan',
  };

  // List of countries for the dropdown
  List<String> get availableCountries => countryCities.keys.toList();

  // Get cities for the selected country
  List<String> get citiesForSelectedCountry {
    if (country.isEmpty) return [];
    final cities = countryCities[country] ?? [];
    // If the current city is not in the list and not empty, add it
    if (city.isNotEmpty && !cities.contains(city)) {
      return [...cities, city];
    }
    return cities;
  }

  @override
  void initState() {
    super.initState();
    if (widget.addressToEdit != null) {
      final data = widget.addressToEdit!.data() as Map<String, dynamic>;
      addressId = widget.addressToEdit!.id;
      
      // Initialize controllers with existing data
      _firstNameController.text = data['firstName'] ?? '';
      _lastNameController.text = data['lastName'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      addressType = data['addressType'] ?? 'Home';
      _streetController.text = data['street'] ?? '';
      _neighborhoodController.text = data['neighborhood'] ?? '';
      _buildingNoController.text = data['buildingNo'] ?? '';
      _apartmentController.text = data['apartment'] ?? '';
      _floorController.text = data['floor'] ?? '';
      _doorNoController.text = data['doorNo'] ?? '';
      // Normalize country name
      String rawCountry = data['country'] ?? '';
      country = countryNameMap[rawCountry] ?? rawCountry;
      state = data['state'] ?? '';
      city = data['city'] ?? '';
      postalCode = data['postalCode'] ?? '';
      latitude = data['latitude'];
      longitude = data['longitude'];
      _addressLabelController.text = data['label'] ?? '';
    }
  }

  @override
  void dispose() {
    // Dispose controllers
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
    _searchController.dispose();
    _scrollController.dispose();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final primaryColor =
        themeNotifier.isSpecialModeActive
            ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade700
            : Colors.red.shade700;
    final accentColor =
        themeNotifier.isSpecialModeActive
            ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade700
            : Colors.red.shade700;
    final l10n = AppLocalizations.of(context)!;

    // Dynamic colors based on theme
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textFieldBgColor =
        isDarkMode ? Color(0xFF2C2C2C) : Colors.grey.shade50;
    final dividerColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: primaryColor,
        title: Text(l10n.addNewAddress, style: TextStyle(color: Colors.white)),
        leading: BackButton(color: Colors.white),
        backgroundColor: isDarkMode 
            ? Colors.red.shade900
            : (themeNotifier.isSpecialModeActive
                ? themeNotifier.getThemeColor(themeNotifier.specialTheme).shade700
                : Colors.red.shade700),
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDarkMode
                    ? [Color(0xFF121212), Color(0xFF1D1D1D)]
                    : [
                      Colors.white,
                      themeNotifier.isSpecialModeActive
                          ? themeNotifier
                              .getThemeColor(themeNotifier.specialTheme)
                              .shade50
                          : Colors.red.shade50,
                    ],
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
                  _buildSectionHeader(
                    l10n.recipientInfo,
                    Icons.person,
                    accentColor,
                  ),
                  SizedBox(height: 15),
                  _buildInputCard(
                    cardColor: cardColor,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: l10n.firstName,
                                controller: _firstNameController,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return l10n.pleaseEnterFirstName;
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_lastNameFocus);
                                },
                                isDarkMode: isDarkMode,
                                accentColor: accentColor,
                                bgColor: textFieldBgColor,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: l10n.lastName,
                                focusNode: _lastNameFocus,
                                controller: _lastNameController,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return l10n.pleaseEnterLastName;
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_phoneFocus);
                                },
                                isDarkMode: isDarkMode,
                                accentColor: accentColor,
                                bgColor: textFieldBgColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          label: l10n.phoneNumber,
                          focusNode: _phoneFocus,
                          keyboardType: TextInputType.phone,
                          controller: _phoneController,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return l10n.pleaseEnterPhoneNumber;
                            }
                            // Basic phone validation
                            if (val.length < 10) {
                              return l10n.invalidPhoneNumber;
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_streetFocus);
                          },
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          bgColor: textFieldBgColor,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 25),
                  _buildSectionHeader(
                    l10n.addressType,
                    Icons.location_on,
                    accentColor,
                  ),
                  SizedBox(height: 15),
                  _buildAddressTypeSelector(
                    isDarkMode: isDarkMode,
                    primaryColor: primaryColor,
                    accentColor: accentColor,
                    cardColor: cardColor,
                  ),

                  SizedBox(height: 25),
                  _buildSectionHeader(
                    l10n.addressDetails,
                    Icons.home,
                    accentColor,
                  ),
                  SizedBox(height: 15),
                  _buildInputCard(
                    cardColor: cardColor,
                    child: Column(
                      children: [
                        _buildTextField(
                          label: l10n.streetAvenue,
                          focusNode: _streetFocus,
                          controller: _streetController,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return l10n.pleaseEnterStreetName;
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_neighborhoodFocus);
                          },
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          bgColor: textFieldBgColor,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          label: l10n.neighborhood,
                          focusNode: _neighborhoodFocus,
                          controller: _neighborhoodController,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return l10n.pleaseEnterNeighborhood;
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_buildingNoFocus);
                          },
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          bgColor: textFieldBgColor,
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: l10n.buildingNo,
                                focusNode: _buildingNoFocus,
                                controller: _buildingNoController,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return l10n.required;
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  FocusScope.of(context).requestFocus(_apartmentFocus);
                                },
                                isDarkMode: isDarkMode,
                                accentColor: accentColor,
                                bgColor: textFieldBgColor,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: l10n.apartmentName,
                                focusNode: _apartmentFocus,
                                controller: _apartmentController,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return l10n.required;
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  FocusScope.of(context).requestFocus(_floorFocus);
                                },
                                isDarkMode: isDarkMode,
                                accentColor: accentColor,
                                bgColor: textFieldBgColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: l10n.floorNo,
                                focusNode: _floorFocus,
                                controller: _floorController,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return l10n.required;
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  FocusScope.of(context).requestFocus(_doorNoFocus);
                                },
                                isDarkMode: isDarkMode,
                                accentColor: accentColor,
                                bgColor: textFieldBgColor,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: l10n.doorNo,
                                focusNode: _doorNoFocus,
                                controller: _doorNoController,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return l10n.required;
                                  }
                                  return null;
                                },
                                isDarkMode: isDarkMode,
                                accentColor: accentColor,
                                bgColor: textFieldBgColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildLocationSelector(
                          isDarkMode: isDarkMode,
                          primaryColor: primaryColor,
                          accentColor: accentColor,
                          cardColor: cardColor,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          label: l10n.addressLabel,
                          hintText: l10n.addressLabelHint,
                          focusNode: _addressLabelFocus,
                          controller: _addressLabelController,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return l10n.pleaseEnterAddressLabel;
                            }
                            return null;
                          },
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          bgColor: textFieldBgColor,
                        ),
                        SizedBox(height: 24),
                        _buildSaveButton(primaryColor: primaryColor),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color accentColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor,
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

  Widget _buildInputCard({required Widget child, required Color cardColor}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
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
    required bool isDarkMode,
    required Color accentColor,
    required Color bgColor,
    TextEditingController? controller,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: bgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade300 : null),
        hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade500 : null),
      ),
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  Widget _buildAddressTypeSelector({
    required bool isDarkMode,
    required Color primaryColor,
    required Color accentColor,
    required Color cardColor,
  }) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;
    final selectedBgColor =
        isDarkMode
            ? Color(0xFF2C2C2C)
            : (themeNotifier.isSpecialModeActive
                ? themeNotifier
                    .getThemeColor(themeNotifier.specialTheme)
                    .shade50
                : Colors.red.shade50);
    final unselectedBgColor = cardColor;
    final selectedBorderColor = accentColor;
    final unselectedBorderColor = Colors.transparent;
    final selectedTextColor = primaryColor;
    final unselectedTextColor =
        isDarkMode ? Colors.grey.shade300 : Colors.black87;
    final dividerColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
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
                      addressType == 'Home'
                          ? selectedBgColor
                          : unselectedBgColor,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  border: Border.all(
                    color:
                        addressType == 'Home'
                            ? selectedBorderColor
                            : unselectedBorderColor,
                    width: addressType == 'Home' ? 2 : 0,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.home, color: primaryColor, size: 28),
                    SizedBox(height: 8),
                    Text(
                      l10n.home,
                      style: TextStyle(
                        fontWeight:
                            addressType == 'Home'
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color:
                            addressType == 'Home'
                                ? selectedTextColor
                                : unselectedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 90, color: dividerColor),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => addressType = 'Work'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color:
                      addressType == 'Work'
                          ? selectedBgColor
                          : unselectedBgColor,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(12),
                  ),
                  border: Border.all(
                    color:
                        addressType == 'Work'
                            ? selectedBorderColor
                            : unselectedBorderColor,
                    width: addressType == 'Work' ? 2 : 0,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.work, color: primaryColor, size: 28),
                    SizedBox(height: 8),
                    Text(
                      l10n.work,
                      style: TextStyle(
                        fontWeight:
                            addressType == 'Work'
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color:
                            addressType == 'Work'
                                ? selectedTextColor
                                : unselectedTextColor,
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

  Widget _buildLocationSelector({
    required bool isDarkMode,
    required Color primaryColor,
    required Color accentColor,
    required Color cardColor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return _buildInputCard(
      cardColor: cardColor,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: country.isEmpty ? null : country,
            decoration: InputDecoration(
              labelText: l10n.country,
              prefixIcon: Icon(Icons.public),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: availableCountries.map((String country) {
              return DropdownMenuItem<String>(
                value: country,
                child: Text(country),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  country = newValue;
                  // Reset city when country changes
                  if (!citiesForSelectedCountry.contains(city)) {
                    city = '';
                  }
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.pleaseSelectCountry;
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: city.isEmpty ? null : city,
            decoration: InputDecoration(
              labelText: l10n.city,
              prefixIcon: Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: citiesForSelectedCountry.map((String city) {
              return DropdownMenuItem<String>(
                value: city,
                child: Text(city),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  city = newValue;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.pleaseSelectCity;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton({required Color primaryColor}) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            themeNotifier.isSpecialModeActive
                ? themeNotifier
                    .getThemeColor(themeNotifier.specialTheme)
                    .shade500
                : Colors.red.shade500,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (themeNotifier.isSpecialModeActive
                    ? themeNotifier
                        .getThemeColor(themeNotifier.specialTheme)
                        .shade300
                    : Colors.red.shade300)
                .withOpacity(0.5),
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
          l10n.saveAddress,
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
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          _showErrorSnackBar(l10n.userNotLoggedIn);
          return;
        }

        _showLoadingDialog();

        final addressData = {
          'userId': uid,
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'phone': _phoneController.text,
          'addressType': addressType,
          'street': _streetController.text,
          'neighborhood': _neighborhoodController.text,
          'buildingNo': _buildingNoController.text,
          'apartment': _apartmentController.text,
          'floor': _floorController.text,
          'doorNo': _doorNoController.text,
          'country': country,
          'state': state,
          'city': city,
          'postalCode': postalCode,
          'label': _addressLabelController.text,
          'updatedAt': Timestamp.now(),
        };

        if (addressId != null) {
          await FirebaseFirestore.instance
              .collection('addresses')
              .doc(addressId)
              .update(addressData);
        } else {
          addressData['createdAt'] = Timestamp.now();
          await FirebaseFirestore.instance
              .collection('addresses')
              .add(addressData);
        }

        Navigator.pop(context); // Dismiss loading dialog
        _showSuccessSnackBar(l10n.addressSaved);

        Future.delayed(Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      } catch (e) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _showErrorSnackBar(l10n.errorSavingAddress(e.toString()));
      }
    } else {
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _showErrorSnackBar(l10n.fillAllFields);
    }
  }

  void _showLoadingDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: dialogBgColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeNotifier.isSpecialModeActive
                        ? themeNotifier.getThemeColor(
                          themeNotifier.specialTheme,
                        )
                        : Colors.red,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  l10n.savingAddress,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
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
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            themeNotifier.isSpecialModeActive
                ? themeNotifier
                    .getThemeColor(themeNotifier.specialTheme)
                    .shade700
                : Colors.red.shade700,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
