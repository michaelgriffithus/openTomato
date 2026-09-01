import 'package:flutter/material.dart';

import '../../../../core/database/database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';

class TodoListItem extends StatelessWidget {
  final TodoItemWithPlant todoWithPlant;
  final VoidCallback onTap;

  const TodoListItem({
    super.key,
    required this.todoWithPlant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final todo = todoWithPlant.todo;
    final plant = todoWithPlant.plant;
    final overdue = todo.dueDate.isBefore(DateTime.now());
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: overdue
                ? AppColors.error.withValues(alpha: 0.5)
                : AppColors.textDisabled.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: _priorityColor(todo.priority),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plant?.name ?? 'General',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: plant == null
                          ? palette.textSecondary
                          : AppColors.primaryDark,
                      fontWeight: plant == null ? null : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateLabel(todo.dueDate, overdue, todo.isRecurring),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: overdue ? AppColors.error : palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(int priority) {
    if (priority <= 1) return AppColors.warning;
    if (priority == 2) return AppColors.primary;
    return AppColors.info;
  }

  String _dateLabel(DateTime date, bool overdue, bool recurring) {
    final day = '${date.month}/${date.day}/${date.year}';
    final suffix = recurring ? ' · repeats' : '';
    return overdue ? 'Overdue · $day$suffix' : 'Due · $day$suffix';
  }
}
