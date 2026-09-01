import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/enums/growth_habit.dart';

class GrowthHabitSelector extends StatelessWidget {
  final GrowthHabit selected;
  final ValueChanged<GrowthHabit> onChanged;

  const GrowthHabitSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Growth habit'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: GrowthHabit.values.map((habit) {
            final isSelected = habit == selected;
            return ChoiceChip(
              label: Text(habit.displayName),
              selected: isSelected,
              onSelected: (value) {
                if (value) onChanged(habit);
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : context.palette.textPrimary,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          selected.description,
          style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
