import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../pages/theme_notifier.dart';

class WheelManagementPage extends StatefulWidget {
  const WheelManagementPage({Key? key}) : super(key: key);

  @override
  State<WheelManagementPage> createState() => _WheelManagementPageState();
}

class _WheelManagementPageState extends State<WheelManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _discountController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> wheelItems = [];

  @override
  void initState() {
    super.initState();
    _loadWheelItems();
  }

  Future<void> _loadWheelItems() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('wheel_settings')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          wheelItems = List<Map<String, dynamic>>.from(data['items'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          wheelItems = [
            {'value': '5%', 'weight': 20},
            {'value': '10%', 'weight': 15},
            {'value': '15%', 'weight': 10},
            {'value': '20%', 'weight': 8},
            {'value': '25%', 'weight': 5},
            {'value': 'Try Again', 'weight': 25},
            {'value': '30%', 'weight': 3},
            {'value': '40%', 'weight': 2},
            {'value': '50%', 'weight': 1},
            {'value': 'Try Again', 'weight': 11},
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading wheel items: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveWheelItems() async {
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('wheel_settings')
          .set({
        'items': wheelItems,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.settingsSaved)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showAddItemDialog() {
    _discountController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addNewDiscount),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _discountController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.discountValue,
                  hintText: '10% or Try Again',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterValue;
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.probability,
                  hintText: '1-100',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterValue;
                  }
                  final number = int.tryParse(value);
                  if (number == null || number < 1 || number > 100) {
                    return AppLocalizations.of(context)!.enterValidNumber;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  wheelItems.add({
                    'value': _discountController.text,
                    'weight': int.parse(_discountController.text),
                  });
                });
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.wheelManagement),
          backgroundColor: isDark ? Colors.red.shade900 : themeColor,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.wheelManagement),
        backgroundColor: isDark ? Colors.red.shade900 : themeColor,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveWheelItems,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppLocalizations.of(context)!.wheelItemsDescription,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: wheelItems.length,
              itemBuilder: (context, index) {
                final item = wheelItems[index];
                return ListTile(
                  key: ValueKey(index),
                  title: Text(item['value']),
                  subtitle: Text(
                    '${AppLocalizations.of(context)!.probability}: ${item['weight']}%',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          // Edit item logic
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            wheelItems.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = wheelItems.removeAt(oldIndex);
                  wheelItems.insert(newIndex, item);
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: Icon(Icons.add),
        backgroundColor: themeColor,
      ),
    );
  }
} 