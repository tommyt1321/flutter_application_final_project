import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/category_icon_mapper.dart';
import '../../models/food_category.dart';
import '../../providers/category_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({this.category, super.key});

  final FoodCategory? category;

  bool get isEditing => category != null;

  @override
  State<CategoryFormDialog> createState() {
    return _CategoryFormDialogState();
  }
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late String _selectedIconKey;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.category?.name ?? '');

    _selectedIconKey = widget.category?.iconKey ?? 'other';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    final provider = context.read<CategoryProvider>();

    final bool success;

    if (widget.isEditing) {
      success = await provider.updateCategory(
        category: widget.category!,
        name: _nameController.text,
        iconKey: _selectedIconKey,
      );
    } else {
      success = await provider.addCategory(
        name: _nameController.text,
        iconKey: _selectedIconKey,
      );
    }

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    final message = provider.errorMessage ?? 'Unable to save the category.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<CategoryProvider, bool>(
      (provider) => provider.isSubmitting,
    );

    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Category' : 'Add Category'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Category name',
                  hint: 'Example: Bakery',
                  prefixIcon: Icons.category_outlined,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    final name = value?.trim() ?? '';

                    if (name.isEmpty) {
                      return 'Please enter a category name.';
                    }

                    if (name.length < 2) {
                      return 'Category name must contain at least 2 characters.';
                    }

                    if (name.length > 30) {
                      return 'Category name cannot exceed 30 characters.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _selectedIconKey,
                  decoration: const InputDecoration(
                    labelText: 'Category icon',
                    prefixIcon: Icon(Icons.emoji_emotions_outlined),
                  ),
                  items: CategoryIconMapper.options.map((option) {
                    return DropdownMenuItem<String>(
                      value: option.keyName,
                      child: Row(
                        children: [
                          Icon(option.icon, size: 21),
                          const SizedBox(width: 12),
                          Text(option.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: isSubmitting
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedIconKey = value;
                          });
                        },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('Cancel'),
        ),
        SizedBox(
          width: 130,
          child: AppButton(
            text: widget.isEditing ? 'Save' : 'Add',
            icon: widget.isEditing ? Icons.save_outlined : Icons.add,
            isLoading: isSubmitting,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
