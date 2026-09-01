import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/repositories/todo_repository.dart';

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepository(ref.watch(todosDaoProvider));
});

final activeTodosProvider = StreamProvider<List<TodoItemWithPlant>>((ref) {
  return ref.watch(todoRepositoryProvider).watchActiveTodos();
});

final plantTodosProvider =
    StreamProvider.family<List<TodoItem>, int>((ref, plantId) {
  return ref.watch(todoRepositoryProvider).watchTodosForPlant(plantId);
});

final todoActionsProvider = Provider<TodoActions>((ref) {
  return TodoActions(ref.watch(todoRepositoryProvider));
});

class TodoActions {
  final TodoRepository _repository;

  const TodoActions(this._repository);

  Future<void> dismissTodo(int id) => _repository.dismissTodo(id);

  Future<int> completeTodo(int id, {String? notes}) =>
      _repository.completeTodo(id, notes: notes);

  Future<void> completeTodoWithJournalEntry(int id, int journalEntryId) =>
      _repository.completeTodoWithJournalEntry(id, journalEntryId);

  Future<void> rescheduleTodo(int id, DateTime dueDate) =>
      _repository.rescheduleTodo(id, dueDate);

  Future<int> deleteTodo(int id) => _repository.deleteTodo(id);

  Future<int> createTodo({
    required String title,
    String? description,
    required DateTime dueDate,
    int priority = 2,
    int? plantId,
    String? recurrenceRule,
  }) {
    return _repository.createTodo(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      plantId: plantId,
      isRecurring: recurrenceRule != null,
      recurrenceRule: recurrenceRule,
    );
  }
}
