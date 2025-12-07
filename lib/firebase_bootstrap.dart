import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Attempts to initialize Firebase using either dart-defines or the platform
/// default files (GoogleService-Info.plist / google-services.json). Returns
/// `true` when Firebase ends up ready, or `false` if configuration is missing.
Future<bool> initializeFirebaseIfAvailable() async {
  if (Firebase.apps.isNotEmpty) return true;
  final options = _optionsOrNull();
  if (options != null) {
    try {
      await Firebase.initializeApp(options: options);
      return true;
    } catch (err, stack) {
      log('Firebase init failed with dart-defines: $err', stackTrace: stack);
      return false;
    }
  }
  try {
    await Firebase.initializeApp();
    return true;
  } catch (err, stack) {
    log(
      'Firebase config missing for ${describeEnum(defaultTargetPlatform)}: $err',
      stackTrace: stack,
    );
    return false;
  }
}

FirebaseOptions? _optionsOrNull() {
  final options = DefaultFirebaseOptions.currentPlatform;
  final values = <String>[
    options.apiKey,
    options.appId,
    options.projectId,
    options.messagingSenderId,
  ];
  final hasPlaceholder =
      values.any((value) => value.startsWith('MISSING_FIREBASE'));
  return hasPlaceholder ? null : options;
}
