import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_final_project/models/app_settings.dart';
import 'package:flutter_application_final_project/providers/settings_provider.dart';
import 'package:flutter_application_final_project/repositories/settings_repository.dart';
import 'package:flutter_application_final_project/screens/profile/appearance_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

void main() {
  const boxName = 'appearance_screen_test_box';

  late Directory temporaryDirectory;
  late Box<AppSettings> settingsBox;
  late SettingsRepository repository;
  late SettingsProvider settingsProvider;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'pantrypal_appearance_test_',
    );

    Hive.init(temporaryDirectory.path);

    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }

    settingsBox = await Hive.openBox<AppSettings>(boxName);

    repository = SettingsRepository(settingsBox);

    settingsProvider = SettingsProvider(repository);

    await settingsProvider.initialize();
  });

  tearDown(() async {
    settingsProvider.dispose();

    if (settingsBox.isOpen) {
      await settingsBox.close();
    }

    await Hive.deleteBoxFromDisk(boxName);

    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  Widget createTestApp() {
    return ChangeNotifierProvider<SettingsProvider>.value(
      value: settingsProvider,
      child: const MaterialApp(home: AppearanceScreen()),
    );
  }

  Future<void> waitForThemeSave(WidgetTester tester) async {
    await tester.pump();

    await tester.runAsync(() async {
      while (settingsProvider.isSaving) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });

    await tester.pump();
  }

  testWidgets('displays all three appearance options', (tester) async {
    await tester.pumpWidget(createTestApp());

    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);

    expect(find.text('System default'), findsOneWidget);

    expect(find.text('Light mode'), findsOneWidget);

    expect(find.text('Dark mode'), findsOneWidget);

    expect(find.text('Choose your theme'), findsOneWidget);
  });

  testWidgets('shows System default as the initial selection', (tester) async {
    await tester.pumpWidget(createTestApp());

    await tester.pumpAndSettle();

    expect(settingsProvider.themeMode, ThemeMode.system);

    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    expect(find.byIcon(Icons.circle_outlined), findsNWidgets(2));
  });

  testWidgets('changes and saves the appearance to dark mode', (tester) async {
    await tester.pumpWidget(createTestApp());

    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark mode'));

    await waitForThemeSave(tester);

    expect(settingsProvider.themeMode, ThemeMode.dark);

    expect(settingsProvider.themeModeLabel, 'Dark');

    expect(repository.getSettings().themeModeKey, 'dark');

    expect(settingsProvider.errorMessage, isNull);
  });

  testWidgets('changes and saves the appearance to light mode', (tester) async {
    await tester.pumpWidget(createTestApp());

    await tester.pumpAndSettle();

    await tester.tap(find.text('Light mode'));

    await waitForThemeSave(tester);

    expect(settingsProvider.themeMode, ThemeMode.light);

    expect(settingsProvider.themeModeLabel, 'Light');

    expect(repository.getSettings().themeModeKey, 'light');
  });

  testWidgets('loads a previously saved dark-mode selection', (tester) async {
    await settingsProvider.setThemeMode(ThemeMode.dark);

    await tester.pumpWidget(createTestApp());

    await tester.pumpAndSettle();

    expect(settingsProvider.themeMode, ThemeMode.dark);

    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    expect(find.byIcon(Icons.circle_outlined), findsNWidgets(2));
  });
}
