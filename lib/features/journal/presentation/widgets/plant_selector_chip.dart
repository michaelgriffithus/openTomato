import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../plants/domain/models/plant_model.dart';

/// Tappable summary of the plants linked to an entry.
class PlantSelectorChips extends StatelessWidget {
  final List<PlantModel> selectedPlants;
  final VoidCallback onTap;

  const PlantSelectorChips({
    super.key,
    required this.selectedPlants,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.grass, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Plants',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  selectedPlants.isEmpty ? Icons.add : Icons.edit,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
            if (selectedPlants.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final plant in selectedPlants)
                    Chip(
                      label: Text(plant.name, style: AppTextStyles.bodySmall),
                      backgroundColor:
                          AppColors.primaryLight.withValues(alpha: 0.3),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                ],
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Tap to link plants (optional)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PlantSelectorDialog extends StatefulWidget {
  final List<PlantModel> availablePlants;
  final List<int> initialSelectedIds;

  const PlantSelectorDialog({
    super.key,
    required this.availablePlants,
    required this.initialSelectedIds,
  });

  @override
  State<PlantSelectorDialog> createState() => _PlantSelectorDialogState();
}

class _PlantSelectorDialogState extends State<PlantSelectorDialog> {
  late final Set<int> _selectedIds = {...widget.initialSelectedIds};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Link plants'),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.availablePlants.isEmpty
            ? const Center(child: Text('No active plants yet'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.availablePlants.length,
                itemBuilder: (context, index) {
                  final plant = widget.availablePlants[index];
                  return CheckboxListTile(
                    title: Text(plant.name),
                    value: _selectedIds.contains(plant.id),
                    activeColor: AppColors.primary,
                    onChanged: (selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (selected == true) {
                          _selectedIds.add(plant.id);
                        } else {
                          _selectedIds.remove(plant.id);
                        }
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds.toList()),
          child: Text('Done (${_selectedIds.length})'),
        ),
      ],
    );
  }
}
