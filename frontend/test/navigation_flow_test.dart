import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swe_flutter/main.dart';
import 'package:swe_flutter/screens/marketing_home_page.dart';
import 'package:swe_flutter/screens/landing_page.dart';
import 'package:swe_flutter/screens/consent_screen.dart';
import 'package:swe_flutter/screens/language_screen.dart';
import 'package:swe_flutter/screens/home_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Full User Journey: Marketing -> Landing -> Consent -> Language -> Home', (WidgetTester tester) async {
    // Set a fixed screen size for testing to avoid overflow
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Build app
    await tester.pumpWidget(const CropAIdApp());
    // Allow animation to run briefly but don't wait for it to settle (infinite)
    await tester.pump(const Duration(milliseconds: 500));

    // 1. Initial Screen: Marketing Home Page
    expect(find.byType(MarketingHomePage), findsOneWidget);
    expect(find.text('Launch Application'), findsOneWidget);

    // Tap 'Launch Application'
    await tester.tap(find.text('Launch Application'));
    await tester.pump(const Duration(seconds: 1));

    // 2. Landing Page
    expect(find.byType(LandingPage), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);

    // Tap 'Continue as Guest'
    await tester.tap(find.text('Continue as Guest'));
    await tester.pump(const Duration(seconds: 1));

    // 3. Consent Screen
    expect(find.byType(ConsentScreen), findsOneWidget);
    expect(find.text('I Agree'), findsOneWidget);

    // Tap 'I Agree'
    await tester.tap(find.text('I Agree'));
    await tester.pump(const Duration(seconds: 1));

    // 4. Language Screen
    expect(find.byType(LanguageScreen), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    // Tap 'English'
    await tester.tap(find.text('English'));
    await tester.pump(const Duration(seconds: 1));

    // 5. Home View
    expect(find.byType(HomeView), findsOneWidget);
    // Grid items should exist
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });
}
