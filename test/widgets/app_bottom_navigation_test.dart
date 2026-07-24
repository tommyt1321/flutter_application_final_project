import 'package:flutter/material.dart';
import 'package:flutter_application_final_project/widgets/app_bottom_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createTestApp({
    required int selectedIndex,
    required ValueChanged<int> onDestinationSelected,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: const Center(child: Text('Test Screen')),
        bottomNavigationBar: AppBottomNavigation(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        ),
      ),
    );
  }

  testWidgets('displays all five navigation destinations', (tester) async {
    await tester.pumpWidget(
      createTestApp(selectedIndex: 0, onDestinationSelected: (_) {}),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Use First'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('returns the selected destination index', (tester) async {
    int? selectedDestination;

    await tester.pumpWidget(
      createTestApp(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          selectedDestination = index;
        },
      ),
    );

    await tester.tap(find.text('Shopping'));
    await tester.pumpAndSettle();

    expect(selectedDestination, 3);
  });

  testWidgets('uses the provided selected index', (tester) async {
    await tester.pumpWidget(
      createTestApp(selectedIndex: 4, onDestinationSelected: (_) {}),
    );

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );

    expect(navigationBar.selectedIndex, 4);
  });
}
