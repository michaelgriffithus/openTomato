import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';

class TodoRepository {
  final TodosDao _dao;

  const TodoRepository(this._dao);

  Stream<List<TodoItemWithPlant>> watchActiveTodos() => _dao.watchActiveTodos();

  Stream<List<TodoItem>> watchTodosForPlant(int plantId) =>
      _dao.watchTodosForPlant(plantId);

  Future<List<TodoItem>> getPendingTodosDueBefore(DateTime cutoff) =>
      _dao.getPendingTodosDueBefore(cutoff);

  Future<TodoItem?> getById(int id) => _dao.getTodoById(id);

  Future<int> createTodo({
    required String title,
    String? description,
    required DateTime dueDate,
    int priority = 2,
    int? plantId,
    bool isRecurring = false,
    String? recurrenceRule,
  }) {
    final cleanDescription = description?.trim();
    return _dao.insertTodo(
      TodoItemsCompanion.insert(
        title: title.trim(),
        description: Value(
          cleanDescription == null || cleanDescription.isEmpty
              ? null
              : cleanDescription,
        ),
        dueDate: dueDate,
        priority: Value(priority.clamp(1, 3)),
        plantId: Value(plantId),
        isRecurring: Value(isRecurring),
        recurrenceRule: Value(recurrenceRule),
      ),
    );
  }

  Future<void> updateTodo({
    required int id,
    required String title,
    String? description,
    required DateTime dueDate,
    required int priority,
    int? plantId,
  }) {
    final cleanDescription = description?.trim();
    return _dao.writeTodo(
      id,
      TodoItemsCompanion(
        title: Value(title.trim()),
        description: Value(
          cleanDescription == null || cleanDescription.isEmpty
              ? null
              : cleanDescription,
        ),
        dueDate: Value(dueDate),
        priority: Value(priority.clamp(1, 3)),
        plantId: Value(plantId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> dismissTodo(int id) => _dao.dismissTodo(id);

  /// Completes the task and, for weekly/daily recurring tasks, schedules
  /// the next occurrence.
  Future<int> completeTodo(int id, {String? notes}) async {
    final entryId = await _dao.completeTodo(id, notes: notes);
    await _scheduleNext(id);
    return entryId;
  }

  Future<void> completeTodoWithJournalEntry(int id, int journalEntryId) async {
    await _dao.completeTodoWithJournalEntry(id, journalEntryId);
    await _scheduleNext(id);
  }

  Future<void> rescheduleTodo(int id, DateTime newDueDate) =>
      _dao.rescheduleTodo(id, newDueDate);

  Future<int> deleteTodo(int id) => _dao.deleteTodo(id);

  Future<void> _scheduleNext(int id) async {
    final todo = await _dao.getTodoById(id);
    if (todo == null || !todo.isRecurring) return;
    final days = switch (todo.recurrenceRule) {
      'daily' => 1,
      'weekly' => 7,
      'biweekly' => 14,
      _ => null,
    };
    if (days == null) return;
    await createTodo(
      title: todo.title,
      description: todo.description,
      dueDate: todo.dueDate.add(Duration(days: days)),
      priority: todo.priority,
      plantId: todo.plantId,
      isRecurring: true,
      recurrenceRule: todo.recurrenceRule,
    );
  }
}
