import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_page_title.dart';
import '../../../../core/widgets/glass_date_time_picker.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../home_assistant/presentation/providers/grow_spaces_providers.dart';
import '../../data/repositories/plants_repository.dart';
import '../../domain/enums/start_method.dart';
import '../providers/plants_providers.dart';

class _SelectedVariety {
  final int id;
  final String name;

  const _SelectedVariety({required this.id, required this.name});
}

class PlantFormScreen extends ConsumerStatefulWidget {
  /// Null creates a plant; non-null edits it.
  final int? plantId;

  const PlantFormScreen({super.key, this.plantId});

  @override
  ConsumerState<PlantFormScreen> createState() => _PlantFormScreenState();
}

class _PlantFormScreenState extends ConsumerState<PlantFormScreen> {
  static const _locations = ['Indoor', 'Greenhouse', 'Outdoor'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _containerController = TextEditingController();
  final _mediumController = TextEditingController();
  final _notesController = TextEditingController();

  _SelectedVariety? _selectedVariety;
  String? _selectedGrowSpaceId;
  String? _location;
  DateTime _startDate = DateTime.now();
  StartMethod _startMethod = StartMethod.seed;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.plantId != null) _loadPlantData();
  }

  Future<void> _loadPlantData() async {
    final loaded = await ref.read(plantByIdProvider(widget.plantId!).future);
    if (loaded == null || !mounted) return;
    final plant = loaded.plant;
    setState(() {
      _nameController.text = plant.name;
      final variety = loaded.variety;
      _selectedVariety = variety == null
          ? null
          : _SelectedVariety(id: variety.id, name: variety.name);
      _startDate = plant.startDate;
      _startMethod = plant.startMethod;
      _selectedGrowSpaceId = plant.growSpaceId;
      _location = plant.location;
      _containerController.text = plant.container ?? '';
      _mediumController.text = plant.medium ?? '';
      _notesController.text = plant.notes ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _containerController.dispose();
    _mediumController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plantId != null;
    final growSpaces =
        ref.watch(growSpacesStreamProvider).valueOrNull ?? const <GrowSpace>[];

    return Scaffold(
      appBar: AppBar(
        title: AppPageTitle(pageName: isEditing ? 'Edit plant' : 'New plant'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassTextField(
              controller: _nameController,
              labelText: 'Plant name',
              hintText: 'e.g. Sungold by the fence',
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter a name'
                  : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final variety = await context.push<Variety>('/variety-picker');
                if (variety != null) {
                  setState(() {
                    _selectedVariety =
                        _SelectedVariety(id: variety.id, name: variety.name);
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Variety',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedVariety?.name ?? 'Tap to choose a variety',
                        style: _selectedVariety == null
                            ? AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textDisabled,
                              )
                            : AppTextStyles.bodyMedium,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassDateTimePicker(
              value: _startDate,
              labelText: 'Start date',
              mode: DateTimePickerMode.dateOnly,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              onChanged: (picked) => setState(() => _startDate = picked),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<StartMethod>(
              key: ValueKey(_startMethod),
              initialValue: _startMethod,
              decoration: const InputDecoration(
                labelText: 'Started as',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final method in StartMethod.values)
                  DropdownMenuItem(
                    value: method,
                    child: Text(method.displayName),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _startMethod = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              key: ValueKey(_resolveGrowSpaceId(growSpaces)),
              initialValue: _resolveGrowSpaceId(growSpaces),
              decoration: const InputDecoration(
                labelText: 'Grow space',
                border: OutlineInputBorder(),
                helperText: 'Which sensors describe this plant\'s air.',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Default grow space'),
                ),
                for (final space in growSpaces)
                  if (!space.isDefault)
                    DropdownMenuItem<String?>(
                      value: space.id,
                      child: Text(space.name),
                    ),
              ],
              onChanged: (value) =>
                  setState(() => _selectedGrowSpaceId = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              key: ValueKey(_location),
              initialValue: _location,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Not set'),
                ),
                for (final location in _locations)
                  DropdownMenuItem<String?>(
                    value: location,
                    child: Text(location),
                  ),
              ],
              onChanged: (value) => setState(() => _location = value),
            ),
            const SizedBox(height: 16),
            GlassTextField(
              controller: _containerController,
              labelText: 'Container or bed (optional)',
              hintText: 'e.g. 5 gallon pot, raised bed',
            ),
            const SizedBox(height: 16),
            GlassTextField(
              controller: _mediumController,
              labelText: 'Soil or medium (optional)',
              hintText: 'e.g. potting mix with compost',
            ),
            const SizedBox(height: 16),
            GlassTextField(
              controller: _notesController,
              labelText: 'Notes (optional)',
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
                  : Text(isEditing ? 'Save changes' : 'Add plant'),
            ),
          ],
        ),
      ),
    );
  }

  String? _clean(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(plantsRepositoryProvider);
      if (widget.plantId != null) {
        await repository.updatePlantDetails(
          plantId: widget.plantId!,
          name: _nameController.text,
          varietyId: _selectedVariety?.id,
          startDate: _startDate,
          startMethod: _startMethod,
          growSpaceId: _selectedGrowSpaceId,
          location: _location,
          container: _clean(_containerController),
          medium: _clean(_mediumController),
          notes: _clean(_notesController),
        );
      } else {
        await repository.createPlant(
          name: _nameController.text,
          varietyId: _selectedVariety?.id,
          startDate: _startDate,
          startMethod: _startMethod,
          growSpaceId: _selectedGrowSpaceId,
          location: _location,
          container: _clean(_containerController),
          medium: _clean(_mediumController),
          notes: _clean(_notesController),
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException
                  ? e.userMessage
                  : 'Could not save this plant. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _resolveGrowSpaceId(List<GrowSpace> spaces) {
    final selected = _selectedGrowSpaceId;
    if (selected == null || selected.isEmpty) return null;
    final exists = spaces.any((s) => s.id == selected && !s.isDefault);
    return exists ? selected : null;
  }
}
