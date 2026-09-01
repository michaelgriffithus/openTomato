import 'package:drift/drift.dart';

import 'journal_entries.dart';

@DataClassName('JournalPhoto')
class JournalPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get journalEntryId =>
      integer().references(JournalEntries, #id, onDelete: KeyAction.cascade)();

  /// Paths are stored relative to the app documents directory (see AppPaths).
  TextColumn get filePath => text()();
  TextColumn get thumbnailPath => text()();
  IntColumn get displayOrder => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
