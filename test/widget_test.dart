import 'dart:io';

import 'package:flutter_application_final_project/app.dart';
import 'package:flutter_application_final_project/models/app_settings.dart';
import 'package:flutter_application_final_project/providers/settings_provider.dart';
import 'package:flutter_application_final_project/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

void main() {
  late Directory temporaryDirectory;
  late Box<AppSettings> settingsBox;
  late SettingsProvider settingsProvider;

  setUpAll(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'pantrypal_widget_test_',
    );

    Hive.init(temporaryDirectory.path);

    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }

    settingsBox = await Hive.openBox<AppSettings>('widget_test_settings_box');

    settingsProvider = SettingsProvider(SettingsRepository(settingsBox));

    await settingsProvider.initialize();
  });

  tearDownAll(() async {
    settingsProvider.dispose();

    await settingsBox.close();

    await Hive.deleteBoxFromDisk('widget_test_settings_box');

    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  testWidgets('Splash screen opens the PantryPal dashboard', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settingsProvider,
        child: const PantryPalApp(),
      ),
    );

    // Verify splash screen.
    expect(find.text('PantryPal'), findsOneWidget);

    expect(find.text('Track food. Reduce waste. Save money.'), findsOneWidget);

    // Finish the splash delay.
    await tester.pump(const Duration(seconds: 2));

    // Start and complete the navigation animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify dashboard.
    expect(find.text('Pantry Overview'), findsOneWidget);

    expect(find.text('Use These First'), findsOneWidget);

    expect(find.text('Welcome to PantryPal'), findsOneWidget);
  });
}
