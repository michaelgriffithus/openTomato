import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/glass_date_time_picker.dart';
import '../../data/models/plant_with_variety.dart';
import '../../data/repositories/plants_repository.dart';
import '../../domain/enums/growth_stage.dart';
import '../providers/plants_providers.dart';

class PlantStageChangeScreen extends ConsumerStatefulWidget {
  const PlantStageChangeScreen({super.key, this.initialPlantId});

  /// Preselects this plant when opened from a plant-specific entry point.
  final int? initialPlantId;

  @override
  ConsumerState<PlantStageChangeScreen> createState() =>
      _PlantStageChangeScreenState();
}

class _PlantStageChangeScreenState
    extends ConsumerState<PlantStageChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _plantId;
  GrowthStage? _stage;
  DateTime _movedAt = DateTime.now();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(activePlantsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              eyebrow: 'What happened?',
              title: 'Move growth stage',
              leading: IconButton(
                tooltip: 'Back',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            Expanded(
              child: plantsAsync.when(
                data: _form,
                loading: () => const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
                error: (error, _) => Center(
                  child: Text('Could not load plants: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(List<PlantWithVariety> plants) {
    if (plants.isEmpty) {
      return const Center(child: Text('Add a plant before moving its stage.'));
    }
    if (_plantId == null) {
      PlantWithVariety? preselected;
      if (plants.length == 1) {
        preselected = plants.single;
      } else if (widget.initialPlantId != null) {
        for (final plant in plants) {
          if (plant.plant.id == widget.initialPlantId) preselected = plant;
        }
      }
      if (preselected != null) {
        final plant = preselected;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _plantId == null) _selectPlant(plant);
        });
      }
    }
    PlantWithVariety? selected;
    for (final plant in plants) {
      if (plant.plant.id == _plantId) selected = plant;
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (plants.length == 1)
            GlassCard(
              child: ListTile(
                leading: const Icon(Icons.grass, color: AppColors.primary),
                title: Text(plants.single.plant.name),
                subtitle: const Text('Automatically selected'),
              ),
            )
          else
            DropdownButtonFormField<int>(
              key: ValueKey(_plantId),
              initialValue: _plantId,
              decoration: const InputDecoration(
                labelText: 'Plant',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final plant in plants)
                  DropdownMenuItem(
                    value: plant.plant.id,
                    child: Text(plant.plant.name),
                  ),
              ],
              onChanged: (id) {
                if (id == null) return;
                _selectPlant(plants.firstWhere((p) => p.plant.id == id));
              },
              validator: (value) => value == null ? 'Choose a plant' : null,
            ),
          const SizedBox(height: 18),
          if (selected != null) ...[
            DropdownButtonFormField<GrowthStage>(
              key: ValueKey('${selected.plant.id}:${_stage?.name}'),
              initialValue: _stage,
              decoration: const InputDecoration(
                labelText: 'New current stage',
                border: OutlineInputBorder(),
                helperText: 'Stage bands on Today follow this.',
              ),
              items: [
                for (final stage in GrowthStage.selectable)
                  DropdownMenuItem(
                    value: stage,
                    child: Text(stage.displayName),
                  ),
              ],
              onChanged: (value) => setState(() => _stage = value),
              validator: (value) => value == null ? 'Choose a stage' : null,
            ),
            if (_stage != null) ...[
              const SizedBox(height: 8),
              Text(
                _stage!.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            GlassDateTimePicker(
              value: _movedAt,
              labelText: 'When',
              mode: DateTimePickerMode.dateOnly,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              onChanged: (picked) => setState(() => _movedAt = picked),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('save-stage-change'),
              onPressed: _saving ? null : () => _save(selected!),
              child: Text(_saving ? 'Saving…' : 'Save stage change'),
            ),
          ],
        ],
      ),
    );
  }

  void _selectPlant(PlantWithVariety selected) {
    setState(() {
      _plantId = selected.plant.id;
      _stage = selected.plant.stage;
      _movedAt = DateTime.now();
    });
  }

  Future<void> _save(PlantWithVariety selected) async {
    if (!_formKey.currentState!.validate() || _stage == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(plantsRepositoryProvider).updatePlantStage(
            plantId: selected.plant.id,
            stage: _stage!,
            startedAt: _movedAt,
            plantName: selected.plant.name,
          );
      ref.invalidate(plantByIdProvider(selected.plant.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stage updated to ${_stage!.displayName}')),
        );
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update stage: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
