import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mkeparkapp_flutter/main.dart';
import 'package:mkeparkapp_flutter/services/user_repository.dart';
import 'package:mkeparkapp_flutter/services/bootstrap_diagnostics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App boots into shell and allows tab switching', (
    tester,
  ) async {
    final repository = await UserRepository.create();
    await tester.pumpWidget(
      MKEParkApp(
        userRepository: repository,
        diagnostics: BootstrapDiagnostics(),
        firebaseReady: false,
      ),
    );
    await tester.pumpAndSettle();

    // Quick start sheet may appear; dismiss if present.
    if (find.text('Quick start').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip').first);
      await tester.pumpAndSettle();
    }

    expect(find.text('Dashboard'), findsWidgets);

    await tester.tap(find.text('Feed'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.view_list_outlined), findsOneWidget);
  });
}
