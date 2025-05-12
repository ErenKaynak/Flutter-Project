import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/providers/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(Icons.language),
      title: Text('Language'),
      trailing: DropdownButton<String>(
        value: languageProvider.currentLocale.languageCode,
        dropdownColor: isDark ? Colors.grey[850] : Colors.white,
        underline: Container(),
        items: [
          DropdownMenuItem(
            value: 'en',
            child: Text('English'),
          ),
          DropdownMenuItem(
            value: 'tr',
            child: Text('Türkçe'),
          ),
          DropdownMenuItem(
            value: 'ar',
            child: Text('العربية'),
          ),
        ],
        onChanged: (String? value) {
          if (value != null) {
            languageProvider.changeLanguage(value);
          }
        },
      ),
    );
  }
} 