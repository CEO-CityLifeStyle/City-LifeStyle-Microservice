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
    apiKey: 'AIzaSyDrOBUrBGRl5IpgnbN3UrCfeySogSQ7rrM',
    appId: '1:305829852130:web:b3b08e3c9585ae8bf43fbb',
    messagingSenderId: '305829852130',
    projectId: 'city-lifestyle-app-prod',
    authDomain: 'city-lifestyle-app-prod.firebaseapp.com',
    storageBucket: 'city-lifestyle-app-prod.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBIUe3hDD0qBqBIq3jMxHENtpzt9UamWcQ',
    appId: '1:305829852130:android:2e0d31700af362a6f43fbb',
    messagingSenderId: '305829852130',
    projectId: 'city-lifestyle-app-prod',
    storageBucket: 'city-lifestyle-app-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAlN2J_Xcn9p39Ea_mhJJWOvyrQ-rFV9ts',
    appId: '1:305829852130:ios:f413b42e4e4af7eff43fbb',
    messagingSenderId: '305829852130',
    projectId: 'city-lifestyle-app-prod',
    storageBucket: 'city-lifestyle-app-prod.firebasestorage.app',
    iosBundleId: 'com.citylifestyle.frontend',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAlN2J_Xcn9p39Ea_mhJJWOvyrQ-rFV9ts',
    appId: '1:305829852130:ios:ca00b3d648774159f43fbb',
    messagingSenderId: '305829852130',
    projectId: 'city-lifestyle-app-prod',
    storageBucket: 'city-lifestyle-app-prod.firebasestorage.app',
    iosBundleId: 'mac.citylifestyle',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDrOBUrBGRl5IpgnbN3UrCfeySogSQ7rrM',
    appId: '1:305829852130:web:c14ef4f42ebf41f7f43fbb',
    messagingSenderId: '305829852130',
    projectId: 'city-lifestyle-app-prod',
    authDomain: 'city-lifestyle-app-prod.firebaseapp.com',
    storageBucket: 'city-lifestyle-app-prod.firebasestorage.app',
  );
}
