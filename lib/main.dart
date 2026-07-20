import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'models/food_category.dart';
import 'providers/category_provider.dart';
import 'repositories/category_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(FoodCategoryAdapter());
  }

  final categoryBox = await Hive.openBox<FoodCategory>(
    HiveBoxes.foodCategories,
  );

  final categoryRepository = CategoryRepository(categoryBox);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CategoryProvider>(
          create: (_) {
            return CategoryProvider(categoryRepository)..initialize();
          },
        ),
      ],
      child: const PantryPalApp(),
    ),
  );
}
