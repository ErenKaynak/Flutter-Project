import 'dart:async';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:engineering_project/assets/components/theme_data.dart';
import 'package:engineering_project/assets/components/onesignal_navigation_observer.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:engineering_project/firebase_options.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:engineering_project/pages/root_page.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:engineering_project/pages/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:engineering_project/providers/cart_provider.dart';
import 'package:engineering_project/providers/language_provider.dart';
import 'package:engineering_project/providers/discount_code_provider.dart';
import 'package:engineering_project/pages/home_page.dart';
import 'package:engineering_project/pages/login_page.dart';
import 'package:engineering_project/services/auth_service.dart';
import 'package:engineering_project/notification-system/services/notification_service.dart';
import 'package:engineering_project/notification-system/models/notification_model.dart';

// Define a global key for the navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const String _kSpecialModeActiveKey = 'special_mode_active';
const String _kSpecialThemeKey = 'special_theme';

Future<void> loadSpecialModePreferences(ThemeNotifier themeNotifier) async {
  final prefs = await SharedPreferences.getInstance();
  bool isSpecialModeActive = prefs.getBool(_kSpecialModeActiveKey) ?? false;
  
  if (isSpecialModeActive) {
    String? themeName = prefs.getString(_kSpecialThemeKey);
    if (themeName != null) {
      try {
        final loadedTheme = SpecialTheme.values.firstWhere(
          (e) => e.toString() == themeName,
          orElse: () => SpecialTheme.none,
        );
        themeNotifier.setSpecialTheme(loadedTheme);
      } catch (e) {
        print("Error parsing saved theme: $e");
        themeNotifier.setSpecialTheme(SpecialTheme.none);
      }
    }
  } else {
    themeNotifier.setSpecialTheme(SpecialTheme.none);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: 'Engineering Project',
            theme: ThemeData(
              primarySwatch: Colors.red,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.red,
              brightness: Brightness.dark,
            ),
            themeMode: themeNotifier.themeMode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    
    if (user != null) {
      // Initialize notification service for the user
      final notificationService = NotificationService();
      notificationService.saveNotificationToFirestore(
        userId: user.uid,
        notification: NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Welcome Back!',
          message: 'You have successfully logged in.',
          timestamp: DateTime.now(),
          type: NotificationType.general,
        ),
      );
      return RootPage();
    }
    
    return LoginPage();
  }
}

class SettingsWidget extends StatelessWidget {
  const SettingsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    return PopupMenuButton<ThemeMode>(
      onSelected: (ThemeMode mode) {
        themeNotifier.setThemeMode(mode);
      },
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: ThemeMode.system,
              child: Text('System Theme'),
            ),
            const PopupMenuItem(
              value: ThemeMode.light,
              child: Text('Light Theme'),
            ),
            const PopupMenuItem(
              value: ThemeMode.dark,
              child: Text('Dark Theme'),
            ),
          ],
    );
  }
}
