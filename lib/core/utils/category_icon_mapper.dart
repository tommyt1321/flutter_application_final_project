import 'package:flutter/material.dart';

class CategoryIconMapper {
  CategoryIconMapper._();

  static IconData fromKey(String iconKey) {
    switch (iconKey) {
      case 'fruit':
        return Icons.local_grocery_store_outlined;

      case 'vegetable':
        return Icons.eco_outlined;

      case 'meat':
        return Icons.restaurant_outlined;

      case 'seafood':
        return Icons.set_meal_outlined;

      case 'dairy':
        return Icons.local_drink_outlined;

      case 'drink':
        return Icons.local_cafe_outlined;

      case 'snack':
        return Icons.fastfood_outlined;

      case 'frozen':
        return Icons.ac_unit_outlined;

      case 'canned':
        return Icons.inventory_2_outlined;

      case 'dry':
        return Icons.rice_bowl_outlined;

      case 'condiment':
        return Icons.kitchen_outlined;

      default:
        return Icons.category_outlined;
    }
  }

  static const List<CategoryIconOption> options = [
    CategoryIconOption(
      keyName: 'fruit',
      displayName: 'Fruit',
      icon: Icons.local_grocery_store_outlined,
    ),
    CategoryIconOption(
      keyName: 'vegetable',
      displayName: 'Vegetable',
      icon: Icons.eco_outlined,
    ),
    CategoryIconOption(
      keyName: 'meat',
      displayName: 'Meat',
      icon: Icons.restaurant_outlined,
    ),
    CategoryIconOption(
      keyName: 'seafood',
      displayName: 'Seafood',
      icon: Icons.set_meal_outlined,
    ),
    CategoryIconOption(
      keyName: 'dairy',
      displayName: 'Dairy',
      icon: Icons.local_drink_outlined,
    ),
    CategoryIconOption(
      keyName: 'drink',
      displayName: 'Drink',
      icon: Icons.local_cafe_outlined,
    ),
    CategoryIconOption(
      keyName: 'snack',
      displayName: 'Snack',
      icon: Icons.fastfood_outlined,
    ),
    CategoryIconOption(
      keyName: 'frozen',
      displayName: 'Frozen',
      icon: Icons.ac_unit_outlined,
    ),
    CategoryIconOption(
      keyName: 'canned',
      displayName: 'Canned',
      icon: Icons.inventory_2_outlined,
    ),
    CategoryIconOption(
      keyName: 'dry',
      displayName: 'Dry Food',
      icon: Icons.rice_bowl_outlined,
    ),
    CategoryIconOption(
      keyName: 'condiment',
      displayName: 'Condiment',
      icon: Icons.kitchen_outlined,
    ),
    CategoryIconOption(
      keyName: 'other',
      displayName: 'Other',
      icon: Icons.category_outlined,
    ),
  ];
}

class CategoryIconOption {
  const CategoryIconOption({
    required this.keyName,
    required this.displayName,
    required this.icon,
  });

  final String keyName;
  final String displayName;
  final IconData icon;
}
