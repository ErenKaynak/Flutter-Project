import 'dart:async';

import 'package:engineering_project/assets/components/theme_data.dart';
import 'package:engineering_project/firebase_options.dart';
import 'package:engineering_project/pages/root_page.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:engineering_project/pages/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
<<<<<<< Updated upstream
  // Ensure proper zone handling
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Make zone errors fatal in debug mode
    if (kDebugMode) {
      BindingBase.debugZoneErrorsAreFatal = true;
    }
    
    runApp(const MyApp());
  }, (error, stack) {
    debugPrint('Caught error: $error');
    debugPrint('Stack trace: $stack');
  });
=======
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
    webProvider: ReCaptchaV3Provider(
      '6Lfg6yArAAAAADqs862rWMhyE4fTd9OEPW-Fxjlh',
    ),
  );

  final themeNotifier = ThemeNotifier();

  // React to system theme change
  WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
    themeNotifier.notifyListeners();
  };

  if (kDebugMode) {
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  runZonedGuarded(
    () {
      runApp(
        ChangeNotifierProvider.value(
          value: themeNotifier,
          child: const MyApp(),
        ),
      );
    },
    (error, stackTrace) {
      print('Caught zoned error: $error\n$stackTrace');
    },
  );
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
<<<<<<< Updated upstream
<<<<<<< Updated upstream
          themeMode: themeNotifier.themeMode,
=======
=======
>>>>>>> Stashed changes
          themeMode:
              themeNotifier.isBlackMode
                  ? ThemeMode.dark
                  : themeNotifier.themeMode,
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
<<<<<<< Updated upstream
<<<<<<< Updated upstream

              if (snapshot.hasData) {
                return const RootScreen();
              }
              
              return WelcomeScreen();
            },
          ),
        ),
      ),
=======
=======
>>>>>>> Stashed changes
              if (snapshot.hasData) {
                return const RootScreen();
              }
              return WelcomeScreen();
            },
          ),
          // BLACK MODE özel durum: Tema verisini override ediyoruz.
          builder: (context, child) {
            if (themeNotifier.isBlackMode) {
              return Theme(
                data: themeNotifier.blackTheme, // kendi blackTheme
                child: child!,
              );
            }
            return child!;
          },
        );
      },
>>>>>>> Stashed changes
    );
  }
}

class SettingsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeMode>(
      onSelected: (ThemeMode mode) {
        Provider.of<ThemeNotifier>(context, listen: false).setThemeMode(mode);
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
