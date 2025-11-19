import 'package:flutter_test/flutter_test.dart';
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mkeparkapp_flutter/main.dart';
import 'package:mkeparkapp_flutter/services/user_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Welcome screen directs unauthenticated users to auth flow', (
    tester,
  ) async {
    final repository = await UserRepository.create();
    await tester.pumpWidget(MKEParkApp(userRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to MKEPark'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Account Access'), findsOneWidget);
=======
import 'package:citysmart_parking_app/main.dart';

void main() {
  testWidgets('App renders WelcomeScreen and navigates to Landing', (
    tester,
  ) async {
    // Build the app
    await tester.pumpWidget(const CitySmartParkingApp());

    // Verify WelcomeScreen content
    expect(find.text('Welcome to CitySmart Parking App'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Navigate to Landing
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify LandingScreen content
    expect(find.text('CitySmart Parking App'), findsOneWidget);
    expect(find.text('Welcome to CitySmart Parking App'), findsOneWidget);
    expect(find.text('Monitor parking regulations in your area'), findsOneWidget);
>>>>>>> 2b87afb11f152c882e984ad699e63f1ed266df51
  });
}
