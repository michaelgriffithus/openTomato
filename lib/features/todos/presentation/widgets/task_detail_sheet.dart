import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../dialogs/todo_form_sheet.dart';
import '../providers/todo_providers.dart';

class TaskDetailSheet extends ConsumerWidget {
  final TodoItemWithPlant todoWithPlant;

  const TaskDetailSheet({super.key, required this.todoWithPlant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final todo = todoWithPlant.todo;
    final plant = todoWithPlant.plant;
    final actions = ref.read(todoActionsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(todo.title, style: AppTextStyles.h3),
            const SizedBox(height: 8),
            if (plant != null)
              Text(
                plant.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Due ${todo.dueDate.month}/${todo.dueDate.day}/${todo.dueDate.year}'
              '${todo.isRecurring ? ' · repeats ${todo.recurrenceRule}' : ''}',
              style: AppTextStyles.bodySmall.copyWith(
                color: palette.textSecondary,
              ),
            ),
            if (todo.description != null &&
                todo.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(todo.description!, style: AppTextStyles.bodyMedium),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                final plantPart =
                    todo.plantId != null ? '&plantId=${todo.plantId}' : '';
                context.push(
                  '/timeline/new?todoId=${todo.id}$plantPart'
                  '&title=${Uri.encodeComponent(todo.title)}',
                );
              },
              icon: const Icon(Icons.note_add),
              label: const Text('Log it as a journal entry'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await actions.completeTodo(todo.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Mark done'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showTodoFormSheet(context, existing: todo);
                    },
                    child: const Text('Edit'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      await actions.dismissTodo(todo.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Dismiss'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
