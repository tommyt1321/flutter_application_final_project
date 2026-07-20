import 'package:flutter_application_final_project/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Splash screen opens the PantryPal dashboard', (tester) async {
    await tester.pumpWidget(const PantryPalApp());

    // Verify splash-screen content.
    expect(find.text('PantryPal'), findsOneWidget);
    expect(find.text('Track food. Reduce waste. Save money.'), findsOneWidget);

    // Complete the two-second splash delay.
    await tester.pump(const Duration(seconds: 2));

    // Process the navigation request.
    await tester.pump();

    // Complete the page transition animation.
    await tester.pump(const Duration(milliseconds: 500));

    // Verify dashboard content.
    expect(find.text('Pantry Overview'), findsOneWidget);
    expect(find.text('Use These First'), findsOneWidget);
    expect(find.text('Welcome to PantryPal'), findsOneWidget);
  });
}
