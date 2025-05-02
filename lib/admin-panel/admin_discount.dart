import 'package:engineering_project/assets/components/discount_code.dart';
import 'package:engineering_project/assets/components/discount_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  DateTime? _selectedExpiryDate;
  bool _hasExpiry = false;
  List<String> _allCategories = ["All"];  // Initialize with just "All"
  List<String> _selectedCategories = [];
  bool _isCreatingCode = false;

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
        discountPercentage: double.parse(_discountPercentageController.text),
        expiryDate: _hasExpiry ? _selectedExpiryDate : null,
        // If no categories are selected or "All" is selected, set to null for all products
        applicableCategories: _selectedCategories.isEmpty || _selectedCategories.contains("All") 
            ? null 
            : _selectedCategories,
        usageLimit: _usageLimitController.text.isEmpty 
            ? 0 
            : int.parse(_usageLimitController.text),
        usageCount: 0,
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

  @override
  void dispose() {
    _codeController.dispose();
    _discountPercentageController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Discount Management'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: isDark ? 0 : 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).iconTheme.color),
            onPressed: _loadDiscountCodes,
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : RefreshIndicator(
              onRefresh: _loadDiscountCodes,
              color: Colors.red,
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
                                ),
                              ),
                              Text(
                                "${_discountCodes.length} codes",
                                style: TextStyle(color: Colors.grey[600]),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
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
        boxShadow: isDark ? [] : [
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.red.shade900 : Colors.red.shade300,
            ),
            child: Icon(
              Icons.discount_outlined,
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
                  "Discount Manager",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.black54,
                  ),
                ),
                Text(
                  "${_discountCodes.length} Active Discounts",
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
    );
  }

  Widget _buildCategorySelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 60,
      margin: EdgeInsets.only(top: 16, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _allCategories.length,
        itemBuilder: (context, index) {
          final category = _allCategories[index];
          final isSelected = _selectedCategories.contains(category);
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(category),
              onSelected: (selected) {
                setState(() {
                  if (category == "All") {
                    if (selected) {
                      // If "All" is selected, clear other selections
                      _selectedCategories = [];
                    }
                  } else {
                    if (selected) {
                      // If a specific category is selected, remove "All" if it was selected
                      _selectedCategories.remove("All");
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  }
                });
              },
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              selectedColor: isDark 
                  ? Colors.red.shade900.withOpacity(0.5) 
                  : Colors.red.shade50,
              checkmarkColor: isDark ? Colors.white : Colors.red.shade700,
              labelStyle: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.red.shade700)
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? (isDark ? Colors.red.shade700 : Colors.red.shade400)
                      : Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateDiscountForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.red.shade700 : Colors.red.shade400,
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
      ),
    );

    return Card(
      elevation: isDark ? 1 : 3,
      color: isDark ? Colors.grey.shade900 : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark 
            ? BorderSide(color: Colors.grey.shade800)
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
                  Icon(Icons.add_circle, color: Colors.red.shade400),
                  SizedBox(width: 8),
                  Text(
                    'Create New Discount Code',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Divider(height: 24),
              
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
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allCategories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: Colors.red.shade100,
                        checkmarkColor: Colors.red.shade700,
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                        side: BorderSide(
                          color: isSelected 
                              ? Colors.red.shade400 
                              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
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
              SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Discount Code',
                  hintText: 'Enter a case-sensitive code',
                  prefixIcon: Icon(Icons.code, color: Colors.red.shade300),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a discount code';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _discountPercentageController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Discount Percentage',
                  hintText: 'Enter a number from 1-99',
                  suffixText: '%',
                  prefixIcon: Icon(Icons.percent, color: Colors.red.shade300),
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
                  } catch (e) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _usageLimitController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Usage Limit (Optional)',
                  hintText: 'Leave empty for unlimited use',
                  prefixIcon: Icon(Icons.repeat, color: Colors.red.shade300),
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
              SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: CheckboxListTile(
                  title: Text('Set Expiration Date'),
                  value: _hasExpiry,
                  activeColor: Colors.red.shade400,
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
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.red.shade300),
                          SizedBox(width: 12),
                          Text(
                            _selectedExpiryDate == null
                                ? 'Select Expiry Date'
                                : 'Expires: ${DateFormat('yyyy-MM-dd').format(_selectedExpiryDate!)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedExpiryDate == null 
                                  ? (isDark ? Colors.grey.shade400 : Colors.grey.shade700) 
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    elevation: 3,
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
                            Icon(Icons.add_circle_outline),
                            SizedBox(width: 8),
                            Text(
                              'CREATE DISCOUNT CODE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_discountCodes.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.discount_outlined,
                size: 70,
                color: isDark ? Colors.grey.shade600 : Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                "No discount codes available",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Create a new discount code above",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final code = _discountCodes[index];
            
            // Simplified status check logic
            String statusText;
            Color statusColor;
            
            if (code.expiryDate != null && code.expiryDate!.isBefore(DateTime.now())) {
              statusText = 'Expired';
              statusColor = Colors.red;
            } else if (code.usageLimit > 0 && code.usageCount >= code.usageLimit) {
              statusText = 'Limit Reached';
              statusColor = Colors.orange;
            } else {
              statusText = 'Active';
              statusColor = Colors.green;
            }
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isDark ? 1 : 2,
              color: isDark ? Colors.grey.shade900 : Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isDark 
                    ? BorderSide(color: Colors.grey.shade800)
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  childrenPadding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Center(
                      child: Text(
                        "${code.discountPercentage.toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    code.code,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Uses: ${(code.usageCount).toString()}/${code.usageLimit > 0 ? code.usageLimit.toString() : 'unlimited'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(code),
                  ),
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(),
                        if (code.expiryDate != null)
                          _buildInfoRow(
                            'Expiry Date', 
                            DateFormat('yyyy-MM-dd').format(code.expiryDate!),
                            Icons.calendar_today,
                          ),
                        if (code.applicableCategories != null && code.applicableCategories!.isNotEmpty)
                          _buildInfoRow(
                            'Categories', 
                            code.applicableCategories!.join(", "),
                            Icons.category,
                          ),
                        _buildInfoRow(
                          'Usage Count', 
                          '${code.usageCount}${code.usageLimit > 0 ? ' of ${code.usageLimit}' : ''}',
                          Icons.people,
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          
                          children: [
                            OutlinedButton.icon(
                              icon: Icon(Icons.delete),
                              label: Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red),
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
              ),
            );
          },
          childCount: _discountCodes.length,
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
}