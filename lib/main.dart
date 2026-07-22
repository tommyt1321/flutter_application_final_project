import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'models/app_settings.dart';
import 'models/food_category.dart';
import 'models/storage_location.dart';
import 'providers/category_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/storage_location_provider.dart';
import 'repositories/category_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/storage_location_repository.dart';

const bool showDevicePreview = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(FoodCategoryAdapter());
  }

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(StorageLocationAdapter());
  }

  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }

  final categoryBox = await Hive.openBox<FoodCategory>(
    HiveBoxes.foodCategories,
  );

  final storageLocationBox = await Hive.openBox<StorageLocation>(
    HiveBoxes.storageLocations,
  );

  final settingsBox = await Hive.openBox<AppSettings>(HiveBoxes.appSettings);

  final categoryRepository = CategoryRepository(categoryBox);

  final storageLocationRepository = StorageLocationRepository(
    storageLocationBox,
  );

  final settingsRepository = SettingsRepository(settingsBox);

  final settingsProvider = SettingsProvider(settingsRepository);

  await settingsProvider.initialize();

  final isDevicePreviewEnabled = !kReleaseMode && showDevicePreview;

  runApp(
    DevicePreview(
      enabled: isDevicePreviewEnabled,
      builder: (context) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<CategoryProvider>(
              create: (_) {
                return CategoryProvider(categoryRepository)..initialize();
              },
            ),
            ChangeNotifierProvider<StorageLocationProvider>(
              create: (_) {
                return StorageLocationProvider(storageLocationRepository)
                  ..initialize();
              },
            ),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider,
            ),
          ],
          child: PantryPalApp(enableDevicePreview: isDevicePreviewEnabled),
        );
      },
    ),
  );
}
