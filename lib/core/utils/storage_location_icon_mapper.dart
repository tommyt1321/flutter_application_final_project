import 'package:flutter/material.dart';

class StorageLocationIconMapper {
  StorageLocationIconMapper._();

  static IconData fromKey(String iconKey) {
    switch (iconKey) {
      case 'pantry':
        return Icons.inventory_2_outlined;

      case 'refrigerator':
        return Icons.kitchen_outlined;

      case 'freezer':
        return Icons.ac_unit_outlined;

      case 'cabinet':
        return Icons.door_sliding_outlined;

      case 'countertop':
        return Icons.countertops_outlined;

      case 'shelf':
        return Icons.view_agenda_outlined;

      case 'basket':
        return Icons.shopping_basket_outlined;

      default:
        return Icons.location_on_outlined;
    }
  }

  static const List<StorageLocationIconOption> options = [
    StorageLocationIconOption(
      keyName: 'pantry',
      displayName: 'Pantry',
      icon: Icons.inventory_2_outlined,
    ),
    StorageLocationIconOption(
      keyName: 'refrigerator',
      displayName: 'Refrigerator',
      icon: Icons.kitchen_outlined,
    ),
    StorageLocationIconOption(
      keyName: 'freezer',
      displayName: 'Freezer',
      icon: Icons.ac_unit_outlined,
    ),
    StorageLocationIconOption(
      keyName: 'cabinet',
      displayName: 'Cabinet',
      icon: Icons.door_sliding_outlined,
    ),
    StorageLocationIconOption(
      keyName: 'countertop',
      displayName: 'Countertop',
      icon: Icons.countertops_outlined,
    ),
    StorageLocationIconOption(
      keyName: 'shelf',
      displayName: 'Shelf',
      icon: Icons.view_agenda_outlined,
    ),
    StorageLocationIconOption(
      keyName: 'basket',
      displayName: 'Basket',
      icon: Icons.shopping_basket_outlined,
    ),
    StorageLocationIconOption(
      keyName: 'other',
      displayName: 'Other',
      icon: Icons.location_on_outlined,
    ),
  ];
}

class StorageLocationIconOption {
  const StorageLocationIconOption({
    required this.keyName,
    required this.displayName,
    required this.icon,
  });

  final String keyName;
  final String displayName;
  final IconData icon;
}
