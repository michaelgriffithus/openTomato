import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/entry_plant_associations.dart';
import '../tables/journal_entries.dart';
import '../tables/plants.dart';

part 'journal_entries_dao.g.dart';

@DriftAccessor(tables: [JournalEntries, EntryPlantAssociations, Plants])
class JournalEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$JournalEntriesDaoMixin {
  JournalEntriesDao(super.db);

  JournalPhotosDao get _photos => db.journalPhotosDao;

  Stream<List<JournalEntryWithPlantsAndPhotosEntity>> watchAllEntries() {
    final query = select(journalEntries)
      ..orderBy([(entry) => OrderingTerm.desc(entry.timestamp)]);
    return query.watch().asyncMap(_attach);
  }

  Stream<List<JournalEntryWithPlantsAndPhotosEntity>> watchEntriesForPlant(
    int plantId,
  ) {
    final query = select(journalEntries).join([
      innerJoin(
        entryPlantAssociations,
        entryPlantAssociations.entryId.equalsExp(journalEntries.id),
      ),
    ])
      ..where(entryPlantAssociations.plantId.equals(plantId))
      ..orderBy([OrderingTerm.desc(journalEntries.timestamp)]);
    return query.watch().asyncMap(
          (rows) => _attach(
            rows.map((row) => row.readTable(journalEntries)).toList(),
          ),
        );
  }

  Future<List<JournalEntryWithPlantsAndPhotosEntity>> _attach(
    List<JournalEntry> entries,
  ) async {
    final entryIds = entries.map((entry) => entry.id).toList(growable: false);
    final photosByEntryId = await _photos.getPhotosForEntries(entryIds);
    final plantsByEntryId = await _getPlantsForEntries(entryIds);
    return [
      for (final entry in entries)
        JournalEntryWithPlantsAndPhotosEntity(
          entry: entry,
          photos: photosByEntryId[entry.id] ?? const <JournalPhoto>[],
          plants: plantsByEntryId[entry.id] ?? const <Plant>[],
        ),
    ];
  }

  Future<JournalEntryDetailsEntity?> getEntryById(int id) async {
    final entry = await (select(journalEntries)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
    if (entry == null) return null;
    final plantsByEntry = await _getPlantsForEntries([id]);
    return JournalEntryDetailsEntity(
      entry: entry,
      photos: await _photos.getPhotosForEntry(id),
      plants: plantsByEntry[id] ?? const <Plant>[],
      nutrientRows: await _photos.getNutrientRowsForEntry(id),
    );
  }

  Future<List<JournalEntry>> getRecentEntries({int limit = 5}) {
    final q = select(journalEntries)
      ..orderBy([(e) => OrderingTerm.desc(e.timestamp)])
      ..limit(limit);
    return q.get();
  }

  Future<List<JournalEntry>> getRecentEntriesForPlants(
    List<int> plantIds, {
    int limit = 5,
  }) async {
    if (plantIds.isEmpty) return const [];
    final query = select(journalEntries).join([
      innerJoin(
        entryPlantAssociations,
        entryPlantAssociations.entryId.equalsExp(journalEntries.id),
      ),
    ])
      ..where(entryPlantAssociations.plantId.isIn(plantIds))
      ..orderBy([OrderingTerm.desc(journalEntries.timestamp)])
      ..limit(limit);
    final rows = await query.get();
    return rows.map((row) => row.readTable(journalEntries)).toList();
  }

  Future<Map<int, List<Plant>>> _getPlantsForEntries(List<int> entryIds) async {
    if (entryIds.isEmpty) return const <int, List<Plant>>{};
    final query = select(plants).join([
      innerJoin(
        entryPlantAssociations,
        entryPlantAssociations.plantId.equalsExp(plants.id),
      ),
    ])
      ..where(entryPlantAssociations.entryId.isIn(entryIds));
    final rows = await query.get();
    final plantsByEntryId = <int, List<Plant>>{};
    for (final row in rows) {
      final entryId = row.readTable(entryPlantAssociations).entryId;
      (plantsByEntryId[entryId] ??= <Plant>[]).add(row.readTable(plants));
    }
    return plantsByEntryId;
  }

  Future<int> insertEntry(JournalEntriesCompanion entry) {
    return into(journalEntries).insert(entry);
  }

  /// Creates or updates the single milestone entry of [entryType] for a plant
  /// (for example the "grow started" note).
  Future<int> upsertPlantMilestone({
    required int plantId,
    required String entryType,
    required DateTime timestamp,
    required String content,
  }) async {
    return transaction(() async {
      final existing = await (select(journalEntries).join([
        innerJoin(
          entryPlantAssociations,
          entryPlantAssociations.entryId.equalsExp(journalEntries.id),
        ),
      ])
            ..where(
              entryPlantAssociations.plantId.equals(plantId) &
                  journalEntries.entryType.equals(entryType),
            )
            ..limit(1))
          .getSingleOrNull();
      if (existing != null) {
        final entry = existing.readTable(journalEntries);
        await (update(journalEntries)..where((row) => row.id.equals(entry.id)))
            .write(
          JournalEntriesCompanion(
            timestamp: Value(timestamp),
            content: Value(content),
            updatedAt: Value(DateTime.now()),
          ),
        );
        return entry.id;
      }
      final entryId = await insertEntry(
        JournalEntriesCompanion.insert(
          timestamp: timestamp,
          content: Value(content),
          entryType: Value(entryType),
        ),
      );
      await associatePlant(entryId, plantId);
      return entryId;
    });
  }

  Future<bool> updateEntry(JournalEntry entry) {
    return update(journalEntries).replace(entry);
  }

  Future<int> deleteEntry(int id) {
    return (delete(journalEntries)..where((e) => e.id.equals(id))).go();
  }

  Future<void> associatePlant(int entryId, int plantId) {
    return into(entryPlantAssociations).insert(
      EntryPlantAssociationsCompanion.insert(
        entryId: entryId,
        plantId: plantId,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<int> removeAllAssociations(int entryId) {
    final q = delete(entryPlantAssociations)
      ..where((a) => a.entryId.equals(entryId));
    return q.go();
  }
}
