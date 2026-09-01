import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/journal_nutrient_rows.dart';
import '../tables/journal_photos.dart';

part 'journal_photos_dao.g.dart';

/// Photos and nutrient line items attached to journal entries.
@DriftAccessor(tables: [JournalPhotos, JournalNutrientRows])
class JournalPhotosDao extends DatabaseAccessor<AppDatabase>
    with _$JournalPhotosDaoMixin {
  JournalPhotosDao(super.db);

  Future<List<JournalPhoto>> getPhotosForEntry(int entryId) {
    return (select(journalPhotos)
          ..where((photo) => photo.journalEntryId.equals(entryId))
          ..orderBy([(photo) => OrderingTerm.asc(photo.displayOrder)]))
        .get();
  }

  Future<Map<int, List<JournalPhoto>>> getPhotosForEntries(
    List<int> entryIds,
  ) async {
    if (entryIds.isEmpty) {
      return const <int, List<JournalPhoto>>{};
    }
    final rows = await (select(journalPhotos)
          ..where((photo) => photo.journalEntryId.isIn(entryIds))
          ..orderBy([
            (photo) => OrderingTerm.asc(photo.journalEntryId),
            (photo) => OrderingTerm.asc(photo.displayOrder),
          ]))
        .get();
    final photosByEntryId = <int, List<JournalPhoto>>{};
    for (final photo in rows) {
      (photosByEntryId[photo.journalEntryId] ??= <JournalPhoto>[]).add(photo);
    }
    return photosByEntryId;
  }

  Future<List<JournalPhoto>> getAllPhotos() {
    return (select(journalPhotos)
          ..orderBy([(photo) => OrderingTerm.desc(photo.createdAt)]))
        .get();
  }

  Future<int> insertPhoto(JournalPhotosCompanion photo) {
    return into(journalPhotos).insert(photo);
  }

  Future<int> deletePhoto(int photoId) {
    return (delete(journalPhotos)..where((p) => p.id.equals(photoId))).go();
  }

  Future<List<JournalNutrientRow>> getNutrientRowsForEntry(int entryId) {
    return (select(journalNutrientRows)
          ..where((row) => row.journalEntryId.equals(entryId))
          ..orderBy([(row) => OrderingTerm.asc(row.displayOrder)]))
        .get();
  }

  /// Replaces all nutrient rows for an entry, preserving displayOrder. The
  /// form always submits the full current row set.
  Future<void> replaceNutrientRowsForEntry(
    int entryId,
    List<JournalNutrientRowsCompanion> rows,
  ) async {
    await transaction(() async {
      await (delete(journalNutrientRows)
            ..where((row) => row.journalEntryId.equals(entryId)))
          .go();
      for (final row in rows) {
        await into(journalNutrientRows).insert(row);
      }
    });
  }
}
