import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

import '../../../../core/database/database.dart';
import '../../../../core/utils/app_paths.dart';
import '../../domain/enums/entry_type.dart';
import '../mappers/journal_domain_mappers.dart';
import '../models/journal_entry_with_details.dart';

/// Writes entries, compresses and stores photos, and keeps nutrient rows and
/// plant links in step. Photo files live under
/// `<documents>/photos/journal/<entryId>/` and are stored as relative paths.
class JournalRepository {
  final JournalEntriesDao _entries;
  final JournalPhotosDao _photos;

  const JournalRepository(this._entries, this._photos);

  static const int maxFullSizePixels = 2048;
  static const int maxThumbnailPixels = 256;
  static const int fullSizeQuality = 85;
  static const int thumbnailQuality = 70;

  Future<int> createEntry({
    required DateTime timestamp,
    required EntryType type,
    String? content,
    List<String> imagePaths = const [],
    List<int> plantIds = const [],
    double? tempF,
    double? humidityPct,
    double? vpdKpa,
    double? soilMoisturePct,
    bool watered = false,
    String? nutrients,
    List<NutrientLineItemModel> nutrientRows = const [],
  }) async {
    return _entries.db.transaction(() async {
      final entryId = await _entries.insertEntry(
        JournalEntriesCompanion.insert(
          timestamp: timestamp,
          content: Value(_clean(content)),
          entryType: Value(type.storageValue),
          tempF: Value(tempF),
          humidityPct: Value(humidityPct),
          vpdKpa: Value(vpdKpa),
          soilMoisturePct: Value(soilMoisturePct),
          watered: Value(watered),
          nutrients: Value(_clean(nutrients)),
        ),
      );
      await _photos.replaceNutrientRowsForEntry(
        entryId,
        _nutrientCompanions(entryId, nutrientRows),
      );
      await _addPhotos(entryId, imagePaths, startIndex: 0);
      for (final plantId in plantIds) {
        await _entries.associatePlant(entryId, plantId);
      }
      return entryId;
    });
  }

  Future<void> updateEntry({
    required JournalEntryModel entry,
    List<String> newImagePaths = const [],
    List<int> photoIdsToDelete = const [],
    List<int>? plantIds,
    List<NutrientLineItemModel> nutrientRows = const [],
  }) async {
    await _entries.db.transaction(() async {
      await _entries.updateEntry(
        JournalEntry(
          id: entry.id,
          timestamp: entry.timestamp,
          content: _clean(entry.content),
          entryType: entry.type.storageValue,
          tempF: entry.tempF,
          humidityPct: entry.humidityPct,
          vpdKpa: entry.vpdKpa,
          soilMoisturePct: entry.soilMoisturePct,
          watered: entry.watered,
          nutrients: _clean(entry.nutrients),
          createdAt: entry.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
      await _photos.replaceNutrientRowsForEntry(
        entry.id,
        _nutrientCompanions(entry.id, nutrientRows),
      );
      for (final photoId in photoIdsToDelete) {
        await _deletePhotoFiles(photoId);
        await _photos.deletePhoto(photoId);
      }
      final existing = await _photos.getPhotosForEntry(entry.id);
      await _addPhotos(entry.id, newImagePaths, startIndex: existing.length);
      if (plantIds != null) {
        await _entries.removeAllAssociations(entry.id);
        for (final plantId in plantIds) {
          await _entries.associatePlant(entry.id, plantId);
        }
      }
    });
  }

  /// Deletes the entry, its rows (cascade), and its photo files.
  Future<void> deleteEntry(int entryId) async {
    final photos = await _photos.getPhotosForEntry(entryId);
    for (final photo in photos) {
      await _deleteFile(photo.filePath);
      await _deleteFile(photo.thumbnailPath);
    }
    await _entries.deleteEntry(entryId);
    if (!AppPaths.isInitialized) return;
    final dir = Directory(_entryDirPath(entryId));
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: false);
      } catch (_) {
        // Not empty or already gone.
      }
    }
  }

  Stream<List<JournalEntryWithPlantsAndPhotos>> watchAllEntries() =>
      _entries.watchAllEntries().map(
            (rows) => rows.map((row) => row.toDomain()).toList(growable: false),
          );

  Stream<List<JournalEntryWithPlantsAndPhotos>> watchEntriesForPlant(
    int plantId,
  ) =>
      _entries.watchEntriesForPlant(plantId).map(
            (rows) => rows.map((row) => row.toDomain()).toList(growable: false),
          );

  Future<JournalEntryDetails?> getEntryById(int entryId) async =>
      (await _entries.getEntryById(entryId))?.toDomain();

  Future<List<JournalEntryModel>> getRecentEntries({int limit = 5}) async =>
      (await _entries.getRecentEntries(limit: limit))
          .map((row) => row.toDomain())
          .toList(growable: false);

  List<JournalNutrientRowsCompanion> _nutrientCompanions(
    int entryId,
    List<NutrientLineItemModel> rows,
  ) {
    final companions = <JournalNutrientRowsCompanion>[];
    for (var i = 0; i < rows.length; i++) {
      final name = rows[i].productName.trim();
      if (name.isEmpty) continue;
      companions.add(
        JournalNutrientRowsCompanion.insert(
          journalEntryId: entryId,
          productName: name,
          amount: Value(_clean(rows[i].amount)),
          displayOrder: i,
        ),
      );
    }
    return companions;
  }

  Future<void> _addPhotos(
    int entryId,
    List<String> sourcePaths, {
    required int startIndex,
  }) async {
    for (var i = 0; i < sourcePaths.length; i++) {
      final saved =
          await _saveAndCompress(entryId, startIndex + i, sourcePaths[i]);
      await _photos.insertPhoto(
        JournalPhotosCompanion.insert(
          journalEntryId: entryId,
          filePath: saved.full,
          thumbnailPath: saved.thumbnail,
          displayOrder: startIndex + i,
        ),
      );
    }
  }

  String _entryDirPath(int entryId) =>
      p.join(AppPaths.documentsDir, 'photos', 'journal', entryId.toString());

  Future<({String full, String thumbnail})> _saveAndCompress(
    int entryId,
    int index,
    String sourcePath,
  ) async {
    final dir = Directory(_entryDirPath(entryId));
    if (!await dir.exists()) await dir.create(recursive: true);
    final base = '${entryId}_${index}_${DateTime.now().millisecondsSinceEpoch}';
    final fullPath = p.join(dir.path, '${base}_full.jpg');
    final thumbPath = p.join(dir.path, '${base}_thumb.jpg');
    final full = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      fullPath,
      minWidth: maxFullSizePixels,
      minHeight: maxFullSizePixels,
      quality: fullSizeQuality,
      format: CompressFormat.jpeg,
    );
    final thumb = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      thumbPath,
      minWidth: maxThumbnailPixels,
      minHeight: maxThumbnailPixels,
      quality: thumbnailQuality,
      format: CompressFormat.jpeg,
    );
    if (full == null || thumb == null) {
      throw Exception('Could not compress the photo.');
    }
    return (
      full: AppPaths.toRelativePath(full.path),
      thumbnail: AppPaths.toRelativePath(thumb.path),
    );
  }

  Future<void> _deletePhotoFiles(int photoId) async {
    final all = await _photos.getAllPhotos();
    for (final photo in all) {
      if (photo.id == photoId) {
        await _deleteFile(photo.filePath);
        await _deleteFile(photo.thumbnailPath);
      }
    }
  }

  Future<void> _deleteFile(String storedPath) async {
    try {
      final file = File(AppPaths.resolveDocumentPath(storedPath));
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Already gone.
    }
  }

  String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
