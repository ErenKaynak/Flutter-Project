import 'package:engineering_project/assets/components/discount_code.dart';
import 'package:engineering_project/assets/components/discount_service.dart';
import 'package:engineering_project/assets/components/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../pages/theme_notifier.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/notification-system/models/notification_model.dart';

class DiscountAdminPage extends StatefulWidget {
  const DiscountAdminPage({Key? key}) : super(key: key);

  @override
  State<DiscountAdminPage> createState() => _DiscountAdminPageState();
}

class _DiscountAdminPageState extends State<DiscountAdminPage> {
  final DiscountService _discountService = DiscountService();
  bool _isLoading = true;
  List<DiscountCode> _discountCodes = [];
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _usageLimitController = TextEditingController();
  final _perUserLimitController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minOrderController = TextEditingController();
  
  DateTime? _selectedExpiryDate;
  bool _hasExpiry = false;
  List<String> _allCategories = ["All"];  // Initialize with just "All"
  List<String> _selectedCategories = [];
  bool _isCreatingCode = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadDiscountCodes();
    
    // You might want to fetch categories from Firestore
    _fetchCategories();
  }

  Future<void> _loadDiscountCodes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _discountCodes = await _discountService.getAllDiscountCodes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading discount codes: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();
      
      // Create a Set to store unique category names
      final Set<String> uniqueCategories = {"All"};  // Start with "All"
      
      // Add fetched categories to the Set
      if (categoriesSnapshot.docs.isNotEmpty) {
        uniqueCategories.addAll(
          categoriesSnapshot.docs
              .map((doc) => doc.data()['name'] as String)
              .where((name) => name != null && name.isNotEmpty)
        );
      }
      
      // Update _allCategories with the unique categories
      setState(() {
        _allCategories = uniqueCategories.toList();
      });
      
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _createDiscountCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreatingCode = true;
    });

    try {
      final newCode = DiscountCode(
        id: '', // Will be assigned by Firestore
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        discountPercentage: double.parse(_discountPercentageController.text),
        minOrderAmount: double.parse(_minOrderController.text),
        expiryDate: _hasExpiry ? _selectedExpiryDate : null,
        // If no categories are selected or "All" is selected, set to null for all products
        applicableCategories: _selectedCategories.isEmpty || _selectedCategories.contains("All") 
            ? null 
            : _selectedCategories,
        usageLimit: _usageLimitController.text.isEmpty 
            ? 0 
            : int.parse(_usageLimitController.text),
        usageCount: 0,
        perUserLimit: _perUserLimitController.text.isEmpty 
            ? 0 
            : int.parse(_perUserLimitController.text),
        receivedAt: DateTime.now(),
      );

      final success = await _discountService.createDiscountCode(newCode);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount code created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form
        _codeController.clear();
        _discountPercentageController.clear();
        _usageLimitController.clear();
        _perUserLimitController.clear();
        _nameController.clear();
        _descriptionController.clear();
        _minOrderController.clear();
        setState(() {
          _selectedExpiryDate = null;
          _hasExpiry = false;
          _selectedCategories = [];
        });
        
        // Reload discount codes
        _loadDiscountCodes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code already exists or other error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating discount code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreatingCode = false;
      });
    }
  }

  Future<void> _deleteDiscountCode(String id) async {
    try {
      final success = await _discountService.deleteDiscountCode(id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount code deleted'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload discount codes
        _loadDiscountCodes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting discount code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectExpiryDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // 5 years from now
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.red.shade400,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      setState(() {
        _selectedExpiryDate = pickedDate;
      });
    }
  }

  void _setFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountPercentageController.dispose();
    _usageLimitController.dispose();
    _perUserLimitController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : const Color(0xFFEF5350);
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Discount Management', style: TextStyle(color: Colors.white)),
        backgroundColor: themeColor,
        elevation: isDark ? 0 : 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDiscountCodes,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: themeColor))
          : RefreshIndicator(
              onRefresh: _loadDiscountCodes,
              color: themeColor,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildCategorySelector(),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSection(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildCreateDiscountForm(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Active Discount Codes',
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                "${_discountCodes.length} codes",
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDiscountCodesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : const Color(0xFFEF5350);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
              : [themeColor.withOpacity(0.8), themeColor.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? themeColor.withOpacity(0.2) : Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              Icons.discount_outlined,
              size: 30,
              color: isDark ? themeColor : Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Discount Manager",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  "${_discountCodes.length} Active Discounts",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : const Color(0xFFEF5350);
    
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _allCategories.length,
        itemBuilder: (context, index) {
          final category = _allCategories[index];
          final isSelected = _selectedCategories.contains(category);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(category),
              onSelected: (selected) {
                setState(() {
                  if (category == "All") {
                    if (selected) {
                      _selectedCategories = [];
                    }
                  } else {
                    if (selected) {
                      _selectedCategories.remove("All");
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  }
                });
              },
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
              selectedColor: isDark 
                  ? themeColor.withOpacity(0.2)
                  : themeColor.withOpacity(0.1),
              checkmarkColor: themeColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? themeColor
                    : (isDark ? Colors.white : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? themeColor
                      : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateDiscountForm() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : const Color(0xFFEF5350);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeColor, width: 2),
      ),
      prefixIconColor: themeColor,
      suffixIconColor: themeColor,
      labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
    );

    return Card(
      elevation: isDark ? 0 : 2,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark 
            ? BorderSide(color: Colors.grey[800]!)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add_circle, color: themeColor),
                  const SizedBox(width: 8),
                  Text(
                    'Create New Discount Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              Text(
                'Applicable Categories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                'Leave empty for all products',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allCategories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: themeColor.withOpacity(0.2),
                        checkmarkColor: themeColor,
                        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        side: BorderSide(
                          color: isSelected ? themeColor : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? themeColor : (isDark ? Colors.white : Colors.black87),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Discount Code',
                  hintText: 'Enter a case-sensitive code',
                  prefixIcon: Icon(Icons.code, color: themeColor),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a discount code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Discount Name',
                  hintText: 'Enter a name for the discount',
                  prefixIcon: Icon(Icons.label, color: themeColor),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a discount name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Description',
                  hintText: 'Enter a description (optional)',
                  prefixIcon: Icon(Icons.description, color: themeColor),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountPercentageController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Discount Percentage',
                  hintText: 'Enter a number from 1-99',
                  suffixText: '%',
                  prefixIcon: Icon(Icons.percent, color: themeColor),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a discount percentage';
                  }
                  try {
                    final percentage = double.parse(value);
                    if (percentage <= 0 || percentage >= 100) {
                      return 'Enter a value between 1 and 99';
                    }
                    if (percentage < 0) {
                      return 'Discount percentage cannot be negative';
                    }
                  } catch (e) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minOrderController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Minimum Order Amount',
                  hintText: 'Enter minimum order amount',
                  prefixIcon: Icon(Icons.monetization_on, color: themeColor),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a minimum order amount';
                  }
                  try {
                    final minOrder = double.parse(value);
                    if (minOrder < 0) {
                      return 'Enter a positive number';
                    }
                  } catch (e) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usageLimitController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Total Usage Limit (Optional)',
                  hintText: 'Leave empty for unlimited total uses',
                  prefixIcon: Icon(Icons.repeat, color: themeColor),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      final limit = int.parse(value);
                      if (limit < 0) {
                        return 'Enter a positive number';
                      }
                    } catch (e) {
                      return 'Enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _perUserLimitController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Per-User Limit (Optional)',
                  hintText: 'Leave empty for unlimited uses per user',
                  prefixIcon: Icon(Icons.person_outline, color: themeColor),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      final limit = int.parse(value);
                      if (limit < 0) {
                        return 'Enter a positive number';
                      }
                    } catch (e) {
                      return 'Enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                child: CheckboxListTile(
                  title: Text(
                    'Set Expiration Date',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  value: _hasExpiry,
                  activeColor: themeColor,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _hasExpiry = value ?? false;
                      if (!_hasExpiry) {
                        _selectedExpiryDate = null;
                      }
                    });
                  },
                ),
              ),
              if (_hasExpiry)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: InkWell(
                    onTap: _selectExpiryDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: themeColor),
                          const SizedBox(width: 12),
                          Text(
                            _selectedExpiryDate == null
                                ? 'Select Expiry Date'
                                : 'Expires: ${DateFormat('yyyy-MM-dd').format(_selectedExpiryDate!)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedExpiryDate == null 
                                  ? (isDark ? Colors.grey[400] : Colors.grey[700]) 
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down, color: themeColor),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    elevation: isDark ? 0 : 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isCreatingCode ? null : _createDiscountCode,
                  child: _isCreatingCode
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'CREATE DISCOUNT CODE',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: Colors.white,
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

  Widget _buildDiscountCodesList() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : const Color(0xFFEF5350);

    if (_discountCodes.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.discount_outlined,
                size: 70,
                color: isDark ? Colors.grey[700] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                "No discount codes available",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Create a new discount code above",
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final code = _discountCodes[index];
            
            String statusText;
            Color statusColor;
            
            if (code.expiryDate != null && code.expiryDate!.isBefore(DateTime.now())) {
              statusText = 'Expired';
              statusColor = themeColor;
            } else if (code.usageLimit > 0 && code.usageCount >= code.usageLimit) {
              statusText = 'Limit Reached';
              statusColor = themeColor.withOpacity(0.7);
            } else {
              statusText = 'Active';
              statusColor = themeColor;
            }
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isDark ? 0 : 2,
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isDark 
                    ? BorderSide(color: Colors.grey[800]!)
                    : BorderSide.none,
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? themeColor.withOpacity(0.2) : themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? themeColor.withOpacity(0.3) : themeColor.withOpacity(0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "${code.discountPercentage.toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        code.code,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Total uses: ${code.usageCount}/${code.usageLimit > 0 ? code.usageLimit.toString() : 'unlimited'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Per user: ${code.perUserLimit > 0 ? code.perUserLimit.toString() : 'unlimited'} uses',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (statusText == 'Active')
                      IconButton(
                        icon: Icon(Icons.send, color: themeColor),
                        tooltip: 'Send notification to users',
                        onPressed: () => _showSendNotificationConfirmation(code),
                      ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: themeColor),
                      onPressed: () => _showDeleteConfirmation(code),
                    ),
                  ],
                ),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      if (code.expiryDate != null)
                        _buildInfoRow(
                          'Expiry Date', 
                          DateFormat('yyyy-MM-dd').format(code.expiryDate!),
                          Icons.calendar_today,
                          themeColor,
                        ),
                      if (code.applicableCategories != null && code.applicableCategories!.isNotEmpty)
                        _buildInfoRow(
                          'Categories', 
                          code.applicableCategories!.join(", "),
                          Icons.category,
                          themeColor,
                        ),
                      _buildInfoRow(
                        'Total Usage', 
                        '${code.usageCount}${code.usageLimit > 0 ? ' of ${code.usageLimit}' : ' (unlimited)'}',
                        Icons.people,
                        themeColor,
                      ),
                      _buildInfoRow(
                        'Per-User Limit', 
                        code.perUserLimit > 0 ? '${code.perUserLimit} uses per user' : 'Unlimited uses per user',
                        Icons.person_outline,
                        themeColor,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: Icon(Icons.delete, color: themeColor),
                            label: Text(
                              'Delete',
                              style: TextStyle(color: themeColor),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: themeColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _showDeleteConfirmation(code),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          childCount: _discountCodes.length,
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon, Color themeColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: themeColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(DiscountCode code) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Delete Discount Code',
                style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you sure you want to delete the discount code:',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        code.code,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "(${code.discountPercentage}% off)",
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteDiscountCode(code.id);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSendNotificationConfirmation(DiscountCode code) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Send Notification',
                style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Send a notification about this discount code to all users:',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code: ${code.code}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        'Discount: ${code.discountPercentage}%',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      if (code.expiryDate != null)
                        Text(
                          'Expires: ${DateFormat('MMM dd, yyyy').format(code.expiryDate!)}',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Send Notification'),
              onPressed: () {
                Navigator.of(context).pop();
                _sendDiscountNotification(code);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendDiscountNotification(DiscountCode code) async {
    if (!mounted) return;
    
    try {
      final success = await NotificationService.sendToAllUsers(
        title: 'Special Discount!',
        message: 'Use code ${code.code} to get ${code.discountPercentage}% off!',
        additionalData: {
          'type': 'promotion',
          'discountCode': code.code,
          'discountPercentage': code.discountPercentage,
          'discountId': code.id,
          if (code.expiryDate != null) 'expiryDate': code.expiryDate!.toIso8601String(),
        },
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount notification sent!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to send notification');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}