import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'firebase_options.dart';
import 'models/app_settings.dart';
import 'models/food_category.dart';
import 'models/storage_location.dart';
import 'models/food_item.dart';
import 'providers/food_item_provider.dart';
import 'providers/category_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/storage_location_provider.dart';
import 'providers/auth_provider.dart';
import 'repositories/food_item_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/storage_location_repository.dart';

const bool showDevicePreview = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before using Firebase Authentication.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize the local Hive database.
  await Hive.initFlutter();

  // Register Hive adapters.
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(FoodCategoryAdapter());
  }

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(StorageLocationAdapter());
  }

  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }

  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(FoodItemAdapter());
  }

  final authRepository = AuthRepository(firebase_auth.FirebaseAuth.instance);

  // Open Hive boxes.
  final categoryBox = await Hive.openBox<FoodCategory>(
    HiveBoxes.foodCategories,
  );

  final storageLocationBox = await Hive.openBox<StorageLocation>(
    HiveBoxes.storageLocations,
  );

  final settingsBox = await Hive.openBox<AppSettings>(HiveBoxes.appSettings);

  // Create repositories.
  final categoryRepository = CategoryRepository(categoryBox);

  final storageLocationRepository = StorageLocationRepository(
    storageLocationBox,
  );

  final foodItemBox = await Hive.openBox<FoodItem>('food_items');

  final foodItemRepository = FoodItemRepository(foodItemBox);

  final settingsRepository = SettingsRepository(settingsBox);

  // Initialize settings before showing the application.
  final settingsProvider = SettingsProvider(settingsRepository);

  await settingsProvider.initialize();

  final isDevicePreviewEnabled = !kReleaseMode && showDevicePreview;

  runApp(
    DevicePreview(
      enabled: isDevicePreviewEnabled,
      builder: (context) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) {
                return AuthProvider(authRepository);
              },
            ),
            ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
              create: (_) {
                return CategoryProvider(categoryRepository);
              },
              update: (_, authProvider, categoryProvider) {
                final provider =
                    categoryProvider ?? CategoryProvider(categoryRepository);

                provider.updateUserId(authProvider.userId);

                return provider;
              },
            ),
            ChangeNotifierProxyProvider<AuthProvider, StorageLocationProvider>(
              create: (_) {
                return StorageLocationProvider(storageLocationRepository);
              },
              update: (_, authProvider, storageLocationProvider) {
                final provider =
                    storageLocationProvider ??
                    StorageLocationProvider(storageLocationRepository);

                provider.updateUserId(authProvider.userId);

                return provider;
              },
            ),
            ChangeNotifierProxyProvider<AuthProvider, FoodItemProvider>(
              create: (_) {
                return FoodItemProvider(foodItemRepository);
              },
              update: (_, authProvider, foodItemProvider) {
                final provider =
                    foodItemProvider ?? FoodItemProvider(foodItemRepository);

                provider.updateUserId(authProvider.userId);

                return provider;
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
