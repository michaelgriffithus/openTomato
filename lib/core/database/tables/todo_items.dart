import 'package:drift/drift.dart';

import 'journal_entries.dart';
import 'plants.dart';

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueDate => dateTime()();

  /// 1 = high, 2 = normal, 3 = low.
  IntColumn get priority => integer().withDefault(const Constant(2))();

  /// pending, completed, dismissed.
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get dismissedAt => dateTime().nullable()();
  IntColumn get plantId => integer()
      .nullable()
      .references(Plants, #id, onDelete: KeyAction.setNull)();
  IntColumn get journalEntryId => integer()
      .nullable()
      .references(JournalEntries, #id, onDelete: KeyAction.setNull)();
  TextColumn get sourceType => text().withDefault(const Constant('manual'))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurrenceRule => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
