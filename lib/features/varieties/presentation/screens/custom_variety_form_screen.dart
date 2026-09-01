import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/widgets/app_page_title.dart';
import '../../domain/enums/growth_habit.dart';
import '../../domain/enums/variety_category.dart';
import '../providers/varieties_providers.dart';
import '../widgets/growth_habit_selector.dart';

class CustomVarietyFormScreen extends ConsumerStatefulWidget {
  const CustomVarietyFormScreen({super.key});

  @override
  ConsumerState<CustomVarietyFormScreen> createState() =>
      _CustomVarietyFormScreenState();
}

class _CustomVarietyFormScreenState
    extends ConsumerState<CustomVarietyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _daysController = TextEditingController();
  final _notesController = TextEditingController();

  GrowthHabit _habit = GrowthHabit.indeterminate;
  VarietyCategory _category = VarietyCategory.slicer;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppPageTitle(pageName: 'Custom variety')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Variety name',
                hintText: 'e.g. Grandma\'s Pink',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter a name'
                  : null,
            ),
            const SizedBox(height: 16),
            GrowthHabitSelector(
              selected: _habit,
              onChanged: (habit) => setState(() => _habit = habit),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<VarietyCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in VarietyCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.displayName),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _daysController,
              decoration: const InputDecoration(
                labelText: 'Days to maturity (optional)',
                hintText: 'e.g. 75, from transplant',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add variety'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(varietiesRepositoryProvider);
      final id = await repository.create(
        name: _nameController.text,
        habit: _habit,
        category: _category,
        daysToMaturity: int.tryParse(_daysController.text.trim()),
        notes: _notesController.text,
      );
      final variety = await repository.getById(id);
      if (mounted && variety != null) context.pop(variety);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException
                  ? e.userMessage
                  : 'Could not save this variety. Is the name already used?',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
