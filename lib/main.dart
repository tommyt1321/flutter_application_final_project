import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/hive_boxes.dart';
import 'models/food_category.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(FoodCategoryAdapter());
  }

  await Hive.openBox<FoodCategory>(HiveBoxes.foodCategories);

  runApp(const PantryPalApp());
}
