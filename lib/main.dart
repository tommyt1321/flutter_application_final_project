import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'firebase_options.dart';
import 'hive_registrar.g.dart';
import 'models/app_settings.dart';
import 'models/food_category.dart';
import 'models/food_item.dart';
import 'models/shopping_item.dart';
import 'models/storage_location.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/food_item_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/shopping_item_provider.dart';
import 'providers/storage_location_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/food_item_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/shopping_item_repository.dart';
import 'repositories/storage_location_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();

  Hive.registerAdapters();

  final authRepository = AuthRepository(firebase_auth.FirebaseAuth.instance);

  final categoryBox = await Hive.openBox<FoodCategory>(
    HiveBoxes.foodCategories,
  );

  final storageLocationBox = await Hive.openBox<StorageLocation>(
    HiveBoxes.storageLocations,
  );

  final settingsBox = await Hive.openBox<AppSettings>(HiveBoxes.appSettings);

  final foodItemBox = await Hive.openBox<FoodItem>('food_items');

  final shoppingItemBox = await Hive.openBox<ShoppingItem>('shopping_items');

  final categoryRepository = CategoryRepository(categoryBox);

  final storageLocationRepository = StorageLocationRepository(
    storageLocationBox,
  );

  final settingsRepository = SettingsRepository(settingsBox);

  final foodItemRepository = FoodItemRepository(foodItemBox);

  final shoppingItemRepository = ShoppingItemRepository(shoppingItemBox);

  final settingsProvider = SettingsProvider(settingsRepository);

  await settingsProvider.initialize();

  runApp(
    MultiProvider(
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

        ChangeNotifierProxyProvider<AuthProvider, ShoppingItemProvider>(
          create: (_) {
            return ShoppingItemProvider(shoppingItemRepository);
          },
          update: (_, authProvider, shoppingItemProvider) {
            final provider =
                shoppingItemProvider ??
                ShoppingItemProvider(shoppingItemRepository);

            provider.updateUserId(authProvider.userId);

            return provider;
          },
        ),

        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: const PantryPalApp(),
    ),
  );
}
