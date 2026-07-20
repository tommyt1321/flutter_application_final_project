import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_final_project/app.dart';

void main() {
  testWidgets('PantryPal splash screen displays correctly', (tester) async {
    await tester.pumpWidget(const PantryPalApp());

    expect(find.text('PantryPal'), findsOneWidget);
    expect(find.text('Track food. Reduce waste. Save money.'), findsOneWidget);
  });
}
