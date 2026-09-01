import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/models/journal_entry_with_details.dart';
import '../../data/repositories/journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(
    ref.watch(journalEntriesDaoProvider),
    ref.watch(journalPhotosDaoProvider),
  );
});

/// Every entry, newest first, with its photos and plants (database rows).
final allJournalEntriesProvider =
    StreamProvider<List<JournalEntryWithPlantsAndPhotosEntity>>((ref) {
  return ref.watch(journalEntriesDaoProvider).watchAllEntries();
});

final plantJournalEntriesProvider =
    StreamProvider.family<List<JournalEntryWithPlantsAndPhotosEntity>, int>(
        (ref, plantId) {
  return ref.watch(journalEntriesDaoProvider).watchEntriesForPlant(plantId);
});

/// Domain view of every entry, newest first.
final journalTimelineEntriesProvider =
    StreamProvider<List<JournalEntryWithPlantsAndPhotos>>((ref) {
  return ref.watch(journalRepositoryProvider).watchAllEntries();
});

final journalEntryByIdProvider =
    FutureProvider.family<JournalEntryDetails?, int>((ref, entryId) {
  // Re-run when the entries table changes.
  ref.watch(allJournalEntriesProvider);
  return ref.watch(journalRepositoryProvider).getEntryById(entryId);
});

/// Newest photo thumbnail for a plant, or null.
final plantThumbnailPathProvider =
    Provider.family<String?, int>((ref, plantId) {
  final entries = ref.watch(plantJournalEntriesProvider(plantId)).valueOrNull;
  if (entries == null) return null;
  for (final entry in entries) {
    if (entry.photos.isNotEmpty) return entry.photos.first.thumbnailPath;
  }
  return null;
});
