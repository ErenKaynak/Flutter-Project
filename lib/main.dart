import 'dart:async';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:engineering_project/assets/components/notification_service.dart';
import 'package:engineering_project/services/notification_init.dart';
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
  // Set up error handling immediately
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    developer.log(details.toString(), name: 'Flutter Error');
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification system (OneSignal + handlers)
  if (!kIsWeb) {
    await NotificationInitializer.initialize();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => DiscountCodeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final languageProvider = context.watch<LanguageProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Engineering Project',
      theme: themeNotifier.isSpecialModeActive
          ? AppTheme.lightTheme.copyWith(
              primaryColor: themeNotifier.getThemeColor(themeNotifier.specialTheme),
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: themeNotifier.getThemeColor(themeNotifier.specialTheme),
                brightness: Brightness.light,
              ),
            )
          : AppTheme.lightTheme,
      darkTheme: themeNotifier.isSpecialModeActive
          ? AppTheme.darkTheme.copyWith(
              primaryColor: themeNotifier.getThemeColor(themeNotifier.specialTheme),
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: themeNotifier.getThemeColor(themeNotifier.specialTheme),
                brightness: Brightness.dark,
              ),
            )
          : AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      locale: languageProvider.currentLocale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Enable navigator observers for OneSignal in-app routing
      navigatorObservers: [
        // Always add the observer - it will handle cases when OneSignal isn't configured
        OneSignalNavigationObserver(),
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('tr'), // Turkish
        Locale('ar'), // Arabic
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/welcome': (context) => const WelcomeScreen(),
        '/root': (context) => const RootPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Add additional error handling in the auth stream
        if (snapshot.hasError) {
          developer.log('Auth stream error: ${snapshot.error}', error: snapshot.error, stackTrace: snapshot.stackTrace);
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('Authentication Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text('${snapshot.error}', textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Update OneSignal with user info when authenticated
          final user = snapshot.data!;
          if (!kIsWeb) {
            NotificationInitializer.updateUserId(user.uid);
            
            // Set user tags for segmentation
            if (user.displayName != null) {
              NotificationInitializer.addUserTag("username", user.displayName!);
            }
            if (user.email != null) {
              NotificationInitializer.addUserTag("email", user.email!);
            }
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/root');
          });
          return const RootPage();
        }

        // Clear OneSignal external user ID when logged out
        if (!kIsWeb) {
          NotificationInitializer.updateUserId(null);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/welcome');
        });
        return const WelcomeScreen();
      },
    );
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
