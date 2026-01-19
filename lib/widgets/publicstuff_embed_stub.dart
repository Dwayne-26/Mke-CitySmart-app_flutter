import 'package:flutter/material.dart';

/// Placeholder for the PublicStuff embed. The real implementation
/// uses `webview_flutter` which can be platform-specific and cause
/// compile-time issues in some build configurations. This placeholder
/// keeps the app building and provides a clear visual replacement.
Widget buildPublicStuffEmbed() {
  return SizedBox(
    height: 420,
    child: Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Public content (web embed) is unavailable in this build.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ),
    ),
  );
}
