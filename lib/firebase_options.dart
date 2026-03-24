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
    // Use the hosting domain (web.app) instead of firebaseapp.com so that
    // iOS Safari/Chrome's ITP does not block the cross-site auth iframe.
    authDomain: 'geo-guess-2001.web.app',
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
    // App ID must match GOOGLE_APP_ID in ios/Runner/GoogleService-Info.plist
    appId: '1:952231467952:ios:1477848ef85138e73f1475',
    messagingSenderId: '952231467952',
    projectId: 'geo-guess-2001',
    storageBucket: 'geo-guess-2001.firebasestorage.app',
    // ⚠️  IMPORTANT: change this to match the Bundle ID you set in Xcode
    // (Runner → Signing & Capabilities → Bundle Identifier)
    // and what you registered in the Firebase Console iOS app.
    iosBundleId: 'com.abdulaziz.geoguessflags',
  );

  // TODO: Register a macOS app in Firebase Console (bundle ID: com.example.geoguessFlags)
  // and replace these credentials with the real macOS GoogleService-Info.plist values.
  // Using iOS credentials as a temporary workaround for development.
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCWGYiJDfWIomZHJ2iXntpo8pocAYZFVK8',
    appId: '1:952231467952:ios:1477848ef85138e73f1475',
    messagingSenderId: '952231467952',
    projectId: 'geo-guess-2001',
    storageBucket: 'geo-guess-2001.firebasestorage.app',
    iosBundleId: 'com.example.geoguessFlags',
  );
}
