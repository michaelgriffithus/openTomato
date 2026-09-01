import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_date_time_picker.dart';
import '../../../plants/presentation/providers/plants_providers.dart';
import '../providers/todo_providers.dart';

Future<void> showTodoFormSheet(
  BuildContext context, {
  TodoItem? existing,
  int? plantId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => TodoFormSheet(existing: existing, initialPlantId: plantId),
  );
}

class TodoFormSheet extends ConsumerStatefulWidget {
  final TodoItem? existing;
  final int? initialPlantId;

  const TodoFormSheet({super.key, this.existing, this.initialPlantId});

  @override
  ConsumerState<TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends ConsumerState<TodoFormSheet> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late DateTime _dueDate = widget.existing?.dueDate ?? DateTime.now();
  late int _priority = widget.existing?.priority ?? 2;
  late int? _plantId = widget.existing?.plantId ?? widget.initialPlantId;
  late String? _recurrence = widget.existing?.recurrenceRule;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plants = ref.watch(activePlantsProvider).valueOrNull ?? const [];
    final plantIds = plants.map((p) => p.plant.id).toSet();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'New task' : 'Edit task',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              autofocus: widget.existing == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Task',
                hintText: 'e.g. Tie up the Sungold to the stake',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            GlassDateTimePicker(
              value: _dueDate,
              labelText: 'Due',
              mode: DateTimePickerMode.dateOnly,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              onChanged: (picked) => setState(() => _dueDate = picked),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              key: ValueKey(_plantId),
              initialValue: plantIds.contains(_plantId) ? _plantId : null,
              decoration: const InputDecoration(
                labelText: 'Plant (optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('General'),
                ),
                for (final plant in plants)
                  DropdownMenuItem<int?>(
                    value: plant.plant.id,
                    child: Text(plant.plant.name),
                  ),
              ],
              onChanged: (value) => setState(() => _plantId = value),
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('High')),
                ButtonSegment(value: 2, label: Text('Normal')),
                ButtonSegment(value: 3, label: Text('Low')),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _recurrence,
              decoration: const InputDecoration(
                labelText: 'Repeat',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Once')),
                DropdownMenuItem(value: 'daily', child: Text('Every day')),
                DropdownMenuItem(value: 'weekly', child: Text('Every week')),
                DropdownMenuItem(
                  value: 'biweekly',
                  child: Text('Every two weeks'),
                ),
              ],
              onChanged: (value) => setState(() => _recurrence = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(widget.existing == null ? 'Add task' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give the task a name.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(todoRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        await ref.read(todoActionsProvider).createTodo(
              title: title,
              description: _description.text,
              dueDate: _dueDate,
              priority: _priority,
              plantId: _plantId,
              recurrenceRule: _recurrence,
            );
      } else {
        await repo.updateTodo(
          id: existing.id,
          title: title,
          description: _description.text,
          dueDate: _dueDate,
          priority: _priority,
          plantId: _plantId,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
