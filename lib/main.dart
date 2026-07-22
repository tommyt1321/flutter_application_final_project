import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'models/food_category.dart';
import 'models/storage_location.dart';
import 'providers/category_provider.dart';
import 'providers/storage_location_provider.dart';
import 'repositories/category_repository.dart';
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

  final categoryBox = await Hive.openBox<FoodCategory>(
    HiveBoxes.foodCategories,
  );

  final storageLocationBox = await Hive.openBox<StorageLocation>(
    HiveBoxes.storageLocations,
  );

  final categoryRepository = CategoryRepository(categoryBox);

  final storageLocationRepository = StorageLocationRepository(
    storageLocationBox,
  );

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
          ],
          child: PantryPalApp(enableDevicePreview: isDevicePreviewEnabled),
        );
      },
    ),
  );
}
