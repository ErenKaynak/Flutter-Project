import 'package:engineering_project/assets/components/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationManagementPage extends StatefulWidget {
  const NotificationManagementPage({super.key});

  @override
  State<NotificationManagementPage> createState() => _NotificationManagementPageState();
}

class _NotificationManagementPageState extends State<NotificationManagementPage> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedTopic = 'all';
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final success = await NotificationService.sendToTopic(
        topic: _selectedTopic,
        title: _titleController.text,
        message: _messageController.text,
      );

      if (success) {
        _titleController.clear();
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send notification')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedTopic,
              decoration: const InputDecoration(
                labelText: 'Send to',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Users')),
                DropdownMenuItem(value: 'premium', child: Text('Premium Users')),
                DropdownMenuItem(value: 'new', child: Text('New Users')),
              ],
              onChanged: (value) {
                setState(() => _selectedTopic = value!);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Notification Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSending ? null : _sendNotification,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isSending
                    ? const CircularProgressIndicator()
                    : const Text('Send Notification'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Recent Notifications:'),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .orderBy('timestamp', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final notification = snapshot.data!.docs[index];
                      return ListTile(
                        title: Text(notification['title']),
                        subtitle: Text(notification['message']),
                        trailing: Text(notification['topic']),
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