import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:engineering_project/pages/login_page.dart';
import 'package:engineering_project/pages/register_page.dart';
import 'package:engineering_project/pages/root_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:engineering_project/providers/language_provider.dart';

import 'theme_notifier.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  String getLogoAssetForTheme(ThemeNotifier themeNotifier, bool isDarkMode) {
    if (themeNotifier.isSpecialModeActive) {
      switch (themeNotifier.specialTheme) {
        case SpecialTheme.blue:
          return isDarkMode
              ? 'lib/assets/Images/app-icon-dark-blue.png'
              : 'lib/assets/Images/app-icon-light-blue.png';
        case SpecialTheme.yellow:
          return isDarkMode
              ? 'lib/assets/Images/app-icon-dark-yellow.png'
              : 'lib/assets/Images/app-icon-light-yellow.png';
        case SpecialTheme.green:
          return isDarkMode
              ? 'lib/assets/Images/app-icon-dark-green.png'
              : 'lib/assets/Images/app-icon-light-green.png';
        case SpecialTheme.orange:
          return isDarkMode
              ? 'lib/assets/Images/app-icon-dark-orange.png'
              : 'lib/assets/Images/app-icon-light-orange.png';
        case SpecialTheme.purple:
          return isDarkMode
              ? 'lib/assets/Images/app-icon-dark-purple.png'
              : 'lib/assets/Images/app-icon-light-purple.png';
        default:
          return isDarkMode
              ? 'lib/assets/Images/app-icon-dark.png'
              : 'lib/assets/Images/app-icon-light.png';
      }
    } else {
      return isDarkMode
          ? 'lib/assets/Images/app-icon-dark.png'
          : 'lib/assets/Images/app-icon-light.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    Widget buildLanguageButton(String code, String label, String flag) {
      final isSelected = languageProvider.currentLocale.languageCode == code;
      return InkWell(
        onTap: () => languageProvider.changeLanguage(code),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (themeNotifier.isSpecialModeActive
                    ? themeNotifier.getThemeColor(themeNotifier.specialTheme).withOpacity(0.1)
                    : Colors.red.withOpacity(0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (themeNotifier.isSpecialModeActive
                      ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                      : Colors.red)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                flag,
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? (themeNotifier.isSpecialModeActive
                          ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
                          : Colors.red)
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient:
                isDarkMode
                    ? null
                    : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        themeNotifier.isSpecialModeActive
                            ? themeNotifier
                                .getThemeColor(themeNotifier.specialTheme)
                                .shade50
                            : Colors.red.shade50,
                        Colors.white,
                      ],
                    ),
            color: isDarkMode ? bgColor : null,
          ),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo or animation at the top
                      Container(
                        height: MediaQuery.of(context).size.height * 0.2,
                        width: MediaQuery.of(context).size.height * 0.2,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[900] : Colors.white54,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  themeNotifier.isSpecialModeActive
                                      ? themeNotifier
                                          .getThemeColor(
                                            themeNotifier.specialTheme,
                                          )
                                          .shade100
                                      : Colors.red.shade100,
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            getLogoAssetForTheme(themeNotifier, isDarkMode),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 80,
                                  color: isDarkMode ? Colors.white54 : Colors.black26,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.welcome,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color:
                              themeNotifier.isSpecialModeActive
                                  ? themeNotifier
                                      .getThemeColor(themeNotifier.specialTheme)
                                      .shade700
                                  : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.appTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey[300] : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: borderColor,
                        spreadRadius: 5,
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeNotifier.isSpecialModeActive
                                ? themeNotifier
                                    .getThemeColor(themeNotifier.specialTheme)
                                    .shade700
                                : Colors.red.shade700,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.login,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.register,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RootScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: themeNotifier.isSpecialModeActive
                                    ? themeNotifier
                                        .getThemeColor(
                                          themeNotifier.specialTheme,
                                        )
                                        .shade700
                                    : Colors.red.shade700,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.guest,
                            style: TextStyle(
                              fontSize: 16,
                              color: themeNotifier.isSpecialModeActive
                                  ? themeNotifier
                                      .getThemeColor(
                                        themeNotifier.specialTheme,
                                      )
                                      .shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.language,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            buildLanguageButton('en', l10n.english, '🇺🇸'),
                            buildLanguageButton('tr', l10n.turkish, '🇹🇷'),
                            buildLanguageButton('ar', l10n.arabic, '🇸🇦'),
                            buildLanguageButton('ur', l10n.urdu, '🇵🇰'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
