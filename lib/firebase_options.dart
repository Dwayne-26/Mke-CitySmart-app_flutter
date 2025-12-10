// Firebase configuration resolved via --dart-define secrets at build time.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDDvudPRiOxuj2blbTlhz9TH27JOJl6pnY',
    appId: '1:802081773281:web:e95fba34813b26ff0009a0',
    messagingSenderId: '802081773281',
    projectId: 'mkeparkapp-6edc3',
    authDomain: 'mkeparkapp-6edc3.firebaseapp.com',
    storageBucket: 'mkeparkapp-6edc3.firebasestorage.app',
    measurementId: 'G-J12YLCNLDY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAh_ZSbyPodEEkBHSBlb9vksmVZnyDZf4U',
    appId: '1:802081773281:android:55de0e46223bddcf0009a0',
    messagingSenderId: '802081773281',
    projectId: 'mkeparkapp-6edc3',
    storageBucket: 'mkeparkapp-6edc3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB-I3Fa-4bmR-rB-jngHkgWQnjTTHTBZDo',
    appId: '1:418926446148:ios:1077e2e334de8b7e631e11',
    messagingSenderId: '418926446148',
    projectId: 'mkeparkapp-1ad15',
    storageBucket: 'mkeparkapp-1ad15.firebasestorage.app',
    iosBundleId: 'com.mkecitysmart.app',
  );

  static const FirebaseOptions macos = android;
  static const FirebaseOptions windows = android;
  static const FirebaseOptions linux = android;
}
