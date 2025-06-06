import 'package:flutter/material.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:engineering_project/assets/components/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminNotificationManagement extends StatefulWidget {
  const AdminNotificationManagement({Key? key}) : super(key: key);

  @override
  State<AdminNotificationManagement> createState() => _AdminNotificationManagementState();
}

class _AdminNotificationManagementState extends State<AdminNotificationManagement> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _discountCodeController = TextEditingController();
  String _selectedType = 'general';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _discountCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!mounted) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final additionalData = {
        'type': _selectedType,
        if (_selectedType == 'promotion' && _discountCodeController.text.isNotEmpty)
          'discountCode': _discountCodeController.text,
      };

      final success = await NotificationService.sendToAllUsers(
        title: _titleController.text,
        message: _messageController.text,
        additionalData: additionalData,
      );

      if (!mounted) return;

      if (!success) {
        throw Exception('Failed to send notification');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification sent successfully!')),
      );

      _titleController.clear();
      _messageController.clear();
      _discountCodeController.clear();
      setState(() {
        _selectedType = 'general';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending notification: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationManagement),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.notificationTitle,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.notificationMessage,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Notification Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'promotion', child: Text('Promotion')),
                  DropdownMenuItem(value: 'order', child: Text('Order')),
                  DropdownMenuItem(value: 'system', child: Text('System')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              if (_selectedType == 'promotion') ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _discountCodeController,
                  decoration: InputDecoration(
                    labelText: 'Discount Code (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendNotification,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text(AppLocalizations.of(context)!.sendNotification),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 