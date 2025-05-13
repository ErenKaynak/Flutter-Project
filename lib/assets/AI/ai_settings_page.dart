import 'package:flutter/material.dart';
import 'package:engineering_project/assets/AI/ngrok_config.dart';

class AISettingsPage extends StatefulWidget {
  const AISettingsPage({super.key});

  @override
  State<AISettingsPage> createState() => _AISettingsPageState();
}

class _AISettingsPageState extends State<AISettingsPage> {
  final TextEditingController _ngrokController = TextEditingController();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNgrokUrl();
  }

  Future<void> _loadNgrokUrl() async {
    try {
      final url = await NgrokConfig.getNgrokUrl();
      if (mounted) {
        setState(() {
          _ngrokController.text = url ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading settings: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveNgrokUrl() async {
    final url = _ngrokController.text.trim();
    
    if (url.isEmpty) {
      await NgrokConfig.clearNgrokUrl();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Using local AI server')),
        );
      }
      return;
    }

    if (!NgrokConfig.isValidNgrokUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid ngrok URL. It should start with https:// and contain .ngrok.io'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await NgrokConfig.setNgrokUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to Use ngrok'),
                  content: const SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Install ngrok on your computer'),
                        Text('2. Start your local AI server (LM Studio)'),
                        Text('3. Run: ngrok http 1234'),
                        Text('4. Copy the https URL from ngrok'),
                        Text('5. Paste it here and save'),
                        SizedBox(height: 16),
                        Text('Note: The ngrok URL changes each time you restart ngrok. You\'ll need to update it here when that happens.'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Configure Remote AI Access',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ngrokController,
              decoration: const InputDecoration(
                labelText: 'ngrok URL',
                hintText: 'https://your-url.ngrok.io',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Leave empty to use local server (localhost:1234)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveNgrokUrl,
              child: const Text('Save Settings'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () async {
                await NgrokConfig.clearNgrokUrl();
                if (mounted) {
                  _ngrokController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Using local AI server')),
                  );
                }
              },
              child: const Text('Clear ngrok URL'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ngrokController.dispose();
    super.dispose();
  }
} 