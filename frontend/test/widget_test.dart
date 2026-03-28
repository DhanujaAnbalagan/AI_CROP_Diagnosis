// This is a basic Flutter widget test.
//
// Updated to work with the new CropAId app structure.

import 'package:flutter_test/flutter_test.dart';

import 'package:swe_flutter/main.dart';

void main() {
  testWidgets('CropAId app builds successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CropAIdApp());

    // Verify that our app starts without errors
    expect(find.byType(CropAIdApp), findsOneWidget);
  });
}
