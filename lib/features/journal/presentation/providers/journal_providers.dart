import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/providers/database_provider.dart';

/// Every entry, newest first, with its photos and plants.
final allJournalEntriesProvider =
    StreamProvider<List<JournalEntryWithPlantsAndPhotosEntity>>((ref) {
  return ref.watch(journalEntriesDaoProvider).watchAllEntries();
});

final plantJournalEntriesProvider =
    StreamProvider.family<List<JournalEntryWithPlantsAndPhotosEntity>, int>(
        (ref, plantId) {
  return ref.watch(journalEntriesDaoProvider).watchEntriesForPlant(plantId);
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
