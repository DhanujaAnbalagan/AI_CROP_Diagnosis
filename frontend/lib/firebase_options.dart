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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAOTDqxHcTAHBGC_XzkqRLOyUu9mCOvR90',
    appId: '1:117592832656:web:6a2c3c8fd7267397b97615',
    messagingSenderId: '117592832656',
    projectId: 'cropaid-e1101',
    authDomain: 'cropaid-e1101.firebaseapp.com',
    storageBucket: 'cropaid-e1101.firebasestorage.app',
    measurementId: 'G-HWBWDJ5WF0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAOTDqxHcTAHBGC_XzkqRLOyUu9mCOvR90',
    appId: '1:117592832656:android:6a2c3c8fd7267397b97615', // Placeholder, usually different for Android
    messagingSenderId: '117592832656',
    projectId: 'cropaid-e1101',
    storageBucket: 'cropaid-e1101.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAOTDqxHcTAHBGC_XzkqRLOyUu9mCOvR90',
    appId: '1:117592832656:ios:6a2c3c8fd7267397b97615', // Placeholder, usually different for iOS
    messagingSenderId: '117592832656',
    projectId: 'cropaid-e1101',
    storageBucket: 'cropaid-e1101.firebasestorage.app',
    iosBundleId: 'com.example.sweFlutter',
  );
}
