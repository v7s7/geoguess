// ============================================================
// IMPORTANT: Replace this file with your real Firebase config.
//
// Steps:
//   1. Go to https://console.firebase.google.com and create a project.
//   2. Enable Auth (Email/Password), Firestore Database.
//   3. Install FlutterFire CLI:
//        dart pub global activate flutterfire_cli
//   4. From this project root run:
//        flutterfire configure
//   This will generate the real DefaultFirebaseOptions below.
// ============================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Replace all values below with your real Firebase config ──

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCSyZPJ4kh9ucW1ArkiMW3HTnBsOwln4rY',
    appId: '1:952231467952:web:9c881afb5625f25a3f1475',
    messagingSenderId: '952231467952',
    projectId: 'geo-guess-2001',
    authDomain: 'geo-guess-2001.firebaseapp.com',
    storageBucket: 'geo-guess-2001.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDp0gQQaV8msHWojA2Rb4dNnRARRYfbqw0',
    appId: '1:952231467952:android:fac2fb34c83817b43f1475',
    messagingSenderId: '952231467952',
    projectId: 'geo-guess-2001',
    storageBucket: 'geo-guess-2001.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCWGYiJDfWIomZHJ2iXntpo8pocAYZFVK8',
    appId: '1:952231467952:ios:f60b4a508f827a8c3f1475',
    messagingSenderId: '952231467952',
    projectId: 'geo-guess-2001',
    storageBucket: 'geo-guess-2001.firebasestorage.app',
    // ⚠️  IMPORTANT: change this to match the Bundle ID you set in Xcode
    // (Runner → Signing & Capabilities → Bundle Identifier)
    // and what you registered in the Firebase Console iOS app.
    iosBundleId: 'com.example.geoguessFlags',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.example.geoguessFlags',
  );
}