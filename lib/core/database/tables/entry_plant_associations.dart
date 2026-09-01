import 'package:drift/drift.dart';

import 'journal_entries.dart';
import 'plants.dart';

@DataClassName('EntryPlantAssociation')
class EntryPlantAssociations extends Table {
  IntColumn get entryId =>
      integer().references(JournalEntries, #id, onDelete: KeyAction.cascade)();
  IntColumn get plantId =>
      integer().references(Plants, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {entryId, plantId};
}
