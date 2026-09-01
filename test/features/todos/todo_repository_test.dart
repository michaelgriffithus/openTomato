import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/core/database/database.dart';
import 'package:open_tomato/features/plants/data/repositories/plants_repository.dart';
import 'package:open_tomato/features/plants/domain/enums/start_method.dart';
import 'package:open_tomato/features/todos/data/repositories/todo_repository.dart';

void main() {
  late AppDatabase db;
  late TodoRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TodoRepository(db.todosDao);
  });

  tearDown(() => db.close());

  test('completing a task writes a journal entry linked to the plant',
      () async {
    final plantId = await PlantsRepository(db.plantsDao).createPlant(
      name: 'Sungold',
      varietyId: null,
      startDate: DateTime(2026, 7, 1),
      startMethod: StartMethod.seed,
    );
    final id = await repo.createTodo(
      title: '  Tie up  ',
      description: '  ',
      dueDate: DateTime(2026, 9, 2),
      plantId: plantId,
    );
    final active = await repo.watchActiveTodos().first;
    expect(active.single.todo.title, 'Tie up');
    expect(active.single.todo.description, isNull);
    expect(active.single.plant!.name, 'Sungold');

    final entryId = await repo.completeTodo(id, notes: 'done with twine');
    final todo = await repo.getById(id);
    expect(todo!.status, 'completed');
    expect(todo.journalEntryId, entryId);
    final entries =
        await db.journalEntriesDao.watchEntriesForPlant(plantId).first;
    expect(entries.first.entry.content, contains('Tie up'));
    expect(entries.first.entry.content, contains('done with twine'));
    expect(await repo.watchActiveTodos().first, isEmpty);
  });

  test('recurring tasks schedule the next occurrence on completion', () async {
    final id = await repo.createTodo(
      title: 'Water',
      dueDate: DateTime(2026, 9, 1),
      isRecurring: true,
      recurrenceRule: 'weekly',
    );
    await repo.completeTodo(id);
    final active = await repo.watchActiveTodos().first;
    expect(active.single.todo.dueDate, DateTime(2026, 9, 8));
    expect(active.single.todo.isRecurring, isTrue);
  });

  test('dismiss and reschedule', () async {
    final id =
        await repo.createTodo(title: 'Prune', dueDate: DateTime(2026, 9, 1));
    await repo.rescheduleTodo(id, DateTime(2026, 9, 5));
    expect((await repo.getById(id))!.dueDate, DateTime(2026, 9, 5));
    await repo.dismissTodo(id);
    expect((await repo.getById(id))!.status, 'dismissed');
    expect(await repo.watchActiveTodos().first, isEmpty);
  });
}
