import 'package:drift/drift.dart';

import 'journal_entries.dart';

@DataClassName('JournalNutrientRow')
class JournalNutrientRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get journalEntryId =>
      integer().references(JournalEntries, #id, onDelete: KeyAction.cascade)();
  TextColumn get productName => text()();
  TextColumn get amount => text().nullable()();
  IntColumn get displayOrder => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
