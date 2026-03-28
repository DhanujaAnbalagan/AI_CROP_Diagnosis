import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swe_flutter/screens/marketing_home_page.dart';
import 'package:swe_flutter/widgets/particle_canvas.dart';

void main() {
  testWidgets('MarketingHomePage renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: MarketingHomePage(
        onLaunch: () {},
        backgroundWidget: const SizedBox(), // Disable animation for test
      ),
    ));
    
    // Pump to ensure layout is done
    await tester.pumpAndSettle();

    // Verify key text elements are present
    expect(find.text('CropAId'), findsOneWidget);
    expect(find.text('Smart Treatment Starts Here'), findsOneWidget);
    expect(find.text('Launch Application'), findsOneWidget);
    
    // Verify sections are present (by checking titles)
    expect(find.text('The Real-World Crisis'), findsOneWidget);
    expect(find.text('Intelligent Decision Support'), findsOneWidget);
    expect(find.text('Powerful Features'), findsOneWidget);
    expect(find.text('Transforming Agriculture'), findsOneWidget);
    expect(find.text('Ready to Transform Your Farming?'), findsOneWidget);

    // Verify ParticleCanvas is NOT present (replaced by SizedBox)
    expect(find.byType(ParticleCanvas), findsNothing);
    expect(find.byType(SizedBox), findsWidgets); // SizedBox is used commonly, so findsWidgets is safer
  });
}
