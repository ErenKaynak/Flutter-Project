// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCvVxL75mFvOCEuPgMrNPiAqI2Rx61CE3Q',
    appId: '1:52042306180:web:69dee152a188e90828e8d1',
    messagingSenderId: '52042306180',
    projectId: 'engineering-project-23d2e',
    authDomain: 'engineering-project-23d2e.firebaseapp.com',
    storageBucket: 'engineering-project-23d2e.firebasestorage.app',
    measurementId: 'G-P530XHEE0H',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBlsfs8I9MrjA7b2pLgougdBFw5pSMjJBM',
    appId: '1:52042306180:android:9ab9790af18ff49428e8d1',
    messagingSenderId: '52042306180',
    projectId: 'engineering-project-23d2e',
    storageBucket: 'engineering-project-23d2e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCbwpXCtr8y0u9mdT8NpFYZL_BYeS_6r9Q',
    appId: '1:52042306180:ios:a4e80cc66309724c28e8d1',
    messagingSenderId: '52042306180',
    projectId: 'engineering-project-23d2e',
    storageBucket: 'engineering-project-23d2e.firebasestorage.app',
    androidClientId: '52042306180-2etoqf1oj33tsq7dtsgdfcaf8gcdp6f3.apps.googleusercontent.com',
    iosClientId: '52042306180-gt9t57c79ahd8bm3qink991fs6lpr96b.apps.googleusercontent.com',
    iosBundleId: 'com.example.engineeringProject.RunnerTests',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCbwpXCtr8y0u9mdT8NpFYZL_BYeS_6r9Q',
    appId: '1:52042306180:ios:39d543be52f0861a28e8d1',
    messagingSenderId: '52042306180',
    projectId: 'engineering-project-23d2e',
    storageBucket: 'engineering-project-23d2e.firebasestorage.app',
    androidClientId: '52042306180-2etoqf1oj33tsq7dtsgdfcaf8gcdp6f3.apps.googleusercontent.com',
    iosClientId: '52042306180-tl2iuj692q1co1vsoit8ganh19ugluhl.apps.googleusercontent.com',
    iosBundleId: 'com.example.engineeringProject',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCvVxL75mFvOCEuPgMrNPiAqI2Rx61CE3Q',
    appId: '1:52042306180:web:1333bdf9994687f928e8d1',
    messagingSenderId: '52042306180',
    projectId: 'engineering-project-23d2e',
    authDomain: 'engineering-project-23d2e.firebaseapp.com',
    storageBucket: 'engineering-project-23d2e.firebasestorage.app',
    measurementId: 'G-GYKSKXJRHK',
  );

}