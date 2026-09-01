import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../dialogs/todo_form_sheet.dart';
import '../providers/todo_providers.dart';
import '../widgets/task_detail_sheet.dart';
import '../widgets/todo_list_item.dart';

class TodosScreen extends ConsumerWidget {
  const TodosScreen({super.key});

  static const _order = ['Overdue', 'Today', 'This week', 'Later'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final todosAsync = ref.watch(activeTodosProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              eyebrow: 'Plan',
              title: 'Tasks',
              leading: IconButton(
                tooltip: 'Back',
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/timeline'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            Expanded(
              child: todosAsync.when(
                data: (todos) {
                  if (todos.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.checklist_outlined,
                      title: 'No tasks',
                      body: 'Add reminders to water, feed, tie up, or prune. '
                          'Finishing one writes a journal entry.',
                      actionLabel: 'Add a task',
                      onAction: () => showTodoFormSheet(context),
                    );
                  }
                  final grouped = _groupByBucket(todos);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    children: [
                      for (final section in _order)
                        if ((grouped[section] ?? []).isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 6),
                            child: Text(
                              section,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: section == 'Overdue'
                                    ? AppColors.error
                                    : palette.textPrimary,
                              ),
                            ),
                          ),
                          for (final item in grouped[section]!)
                            TodoListItem(
                              todoWithPlant: item,
                              onTap: () => showModalBottomSheet<void>(
                                context: context,
                                showDragHandle: true,
                                builder: (_) =>
                                    TaskDetailSheet(todoWithPlant: item),
                              ),
                            ),
                        ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Could not load tasks: $error')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTodoFormSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Task'),
      ),
    );
  }

  Map<String, List<TodoItemWithPlant>> _groupByBucket(
    List<TodoItemWithPlant> items,
  ) {
    final buckets = {for (final key in _order) key: <TodoItemWithPlant>[]};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));
    for (final item in items) {
      final d = item.todo.dueDate;
      final due = DateTime(d.year, d.month, d.day);
      if (due.isBefore(today)) {
        buckets['Overdue']!.add(item);
      } else if (due.isAtSameMomentAs(today)) {
        buckets['Today']!.add(item);
      } else if (due.isBefore(weekEnd)) {
        buckets['This week']!.add(item);
      } else {
        buckets['Later']!.add(item);
      }
    }
    return buckets;
  }
}
