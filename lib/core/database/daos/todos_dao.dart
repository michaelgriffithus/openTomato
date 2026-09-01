import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/entry_plant_associations.dart';
import '../tables/journal_entries.dart';
import '../tables/plants.dart';
import '../tables/todo_items.dart';

part 'todos_dao.g.dart';

class TodoItemWithPlant {
  final TodoItem todo;
  final Plant? plant;

  const TodoItemWithPlant({required this.todo, required this.plant});
}

@DriftAccessor(
  tables: [TodoItems, Plants, JournalEntries, EntryPlantAssociations],
)
class TodosDao extends DatabaseAccessor<AppDatabase> with _$TodosDaoMixin {
  TodosDao(super.db);

  Stream<List<TodoItemWithPlant>> watchActiveTodos() {
    final query = select(todoItems)
      ..where((t) => t.status.equals('pending'))
      ..orderBy([
        (t) => OrderingTerm.asc(t.dueDate),
        (t) => OrderingTerm.asc(t.priority),
      ]);
    return query.watch().asyncMap(_withPlants);
  }

  Stream<List<TodoItem>> watchTodosForPlant(int plantId) {
    return (select(todoItems)
          ..where((t) => t.plantId.equals(plantId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<List<TodoItem>> getPendingTodosDueBefore(DateTime cutoff) {
    return (select(todoItems)
          ..where(
            (t) =>
                t.status.equals('pending') &
                t.dueDate.isSmallerOrEqualValue(cutoff),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.dueDate),
            (t) => OrderingTerm.asc(t.priority),
          ]))
        .get();
  }

  Future<List<TodoItem>> getTodosDueOnDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(todoItems)
          ..where(
            (t) =>
                t.status.equals('pending') &
                t.dueDate.isBiggerOrEqualValue(start) &
                t.dueDate.isSmallerThanValue(end),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.priority),
            (t) => OrderingTerm.asc(t.dueDate),
          ]))
        .get();
  }

  Future<TodoItem?> getTodoById(int id) {
    return (select(todoItems)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertTodo(TodoItemsCompanion todo) {
    return into(todoItems).insert(todo);
  }

  Future<int> writeTodo(int id, TodoItemsCompanion companion) {
    return (update(todoItems)..where((t) => t.id.equals(id))).write(companion);
  }

  Future<void> dismissTodo(int id) async {
    final now = DateTime.now();
    await writeTodo(
      id,
      TodoItemsCompanion(
        status: const Value('dismissed'),
        dismissedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Completes a task and records a journal entry for it.
  Future<int> completeTodo(int id, {String? notes}) async {
    return db.transaction(() async {
      final todo = await getTodoById(id);
      if (todo == null) {
        throw StateError('Task not found: $id');
      }
      final now = DateTime.now();
      final entryId = await into(journalEntries).insert(
        JournalEntriesCompanion.insert(
          timestamp: now,
          content: Value(_buildJournalContent(todo, notes)),
          entryType: const Value('note'),
        ),
      );
      if (todo.plantId != null) {
        await into(entryPlantAssociations).insert(
          EntryPlantAssociationsCompanion.insert(
            entryId: entryId,
            plantId: todo.plantId!,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      await writeTodo(
        id,
        TodoItemsCompanion(
          status: const Value('completed'),
          completedAt: Value(now),
          journalEntryId: Value(entryId),
          updatedAt: Value(now),
        ),
      );
      return entryId;
    });
  }

  Future<void> completeTodoWithJournalEntry(int id, int journalEntryId) async {
    final now = DateTime.now();
    await writeTodo(
      id,
      TodoItemsCompanion(
        status: const Value('completed'),
        completedAt: Value(now),
        journalEntryId: Value(journalEntryId),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> rescheduleTodo(int id, DateTime newDueDate) async {
    await writeTodo(
      id,
      TodoItemsCompanion(
        dueDate: Value(newDueDate),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteTodo(int id) {
    return (delete(todoItems)..where((t) => t.id.equals(id))).go();
  }

  Future<List<TodoItemWithPlant>> _withPlants(List<TodoItem> todos) async {
    final ids = todos.map((t) => t.plantId).whereType<int>().toSet().toList();
    final plantRows = ids.isEmpty
        ? const <Plant>[]
        : await (select(plants)..where((p) => p.id.isIn(ids))).get();
    final byId = {for (final plant in plantRows) plant.id: plant};
    return [
      for (final todo in todos)
        TodoItemWithPlant(todo: todo, plant: byId[todo.plantId]),
    ];
  }

  String _buildJournalContent(TodoItem todo, String? notes) {
    final buffer = StringBuffer(todo.title.trim());
    if (todo.description != null && todo.description!.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln()
        ..write(todo.description!.trim());
    }
    if (notes != null && notes.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln()
        ..write(notes.trim());
    }
    return buffer.toString();
  }
}
