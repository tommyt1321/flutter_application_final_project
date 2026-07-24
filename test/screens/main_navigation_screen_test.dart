import 'package:flutter/material.dart';
import 'package:flutter_application_final_project/screens/navigation/main_navigation_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createTestApp() {
    return const MaterialApp(home: MainNavigationScreen());
  }

  testWidgets('starts on the Home destination', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pump();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );

    final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));

    expect(navigationBar.selectedIndex, 0);
    expect(indexedStack.index, 0);
  });

  testWidgets('switches from Home to Inventory', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pump();

    await tester.tap(find.text('Inventory'));
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );

    final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));

    expect(navigationBar.selectedIndex, 1);
    expect(indexedStack.index, 1);
  });

  testWidgets('switches between all navigation destinations', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pump();

    await _selectDestination(tester, label: 'Use First', expectedIndex: 2);

    await _selectDestination(tester, label: 'Shopping', expectedIndex: 3);

    await _selectDestination(tester, label: 'Profile', expectedIndex: 4);

    await _selectDestination(tester, label: 'Home', expectedIndex: 0);
  });

  testWidgets('keeps all five main screens inside an IndexedStack', (
    tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pump();

    final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));

    expect(indexedStack.children.length, 5);
    expect(indexedStack.index, 0);
  });
}

Future<void> _selectDestination(
  WidgetTester tester, {
  required String label,
  required int expectedIndex,
}) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();

  final navigationBar = tester.widget<NavigationBar>(
    find.byType(NavigationBar),
  );

  final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));

  expect(navigationBar.selectedIndex, expectedIndex);

  expect(indexedStack.index, expectedIndex);
}
