import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'firebase_options.dart';

/// Attempts to initialize Firebase using either dart-defines or the platform
/// default files (GoogleService-Info.plist / google-services.json). Returns
/// `true` when Firebase ends up ready, or `false` if configuration is missing.
Future<bool> initializeFirebaseIfAvailable() async {
  if (Firebase.apps.isNotEmpty) return true;
  final options = await _optionsOrNull();
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
      'Firebase config missing for ${defaultTargetPlatform.name}: $err',
      stackTrace: stack,
    );
    return false;
  }
}

Future<FirebaseOptions?> _optionsOrNull() async {
  if (kIsWeb) {
    final webOptions = await _loadWebFirebaseOptions();
    if (webOptions != null) return webOptions;
  }
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

Future<FirebaseOptions?> _loadWebFirebaseOptions() async {
  try {
    final uri = Uri.parse('firebase-config.json');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      log('Firebase web config not found (HTTP ${response.statusCode}).');
      return null;
    }
    final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    const requiredKeys = [
      'apiKey',
      'appId',
      'messagingSenderId',
      'projectId',
    ];
    for (final key in requiredKeys) {
      final value = data[key];
      if (value == null || (value is String && value.trim().isEmpty)) {
        log('Firebase web config missing $key.');
        return null;
      }
    }
    return FirebaseOptions(
      apiKey: data['apiKey'] as String,
      appId: data['appId'] as String,
      messagingSenderId: data['messagingSenderId'] as String,
      projectId: data['projectId'] as String,
      authDomain: data['authDomain'] as String?,
      databaseURL: data['databaseURL'] as String?,
      measurementId: data['measurementId'] as String?,
      storageBucket: data['storageBucket'] as String?,
    );
  } catch (err, stack) {
    log('Failed to load firebase-config.json: $err', stackTrace: stack);
    return null;
  }
}
