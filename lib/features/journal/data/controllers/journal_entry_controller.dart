import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/utils/environment_readings.dart';
import '../../../plants/data/repositories/plants_repository.dart';
import '../../../plants/domain/models/plant_model.dart';
import '../../../todos/presentation/providers/todo_providers.dart';
import '../../domain/enums/entry_type.dart';
import '../../presentation/providers/journal_providers.dart';
import '../models/journal_entry_with_details.dart';
import '../repositories/journal_repository.dart';

/// Values the form starts from, for a new or an existing entry.
class JournalEntryFormInitialData {
  final int? entryId;
  final EntryType type;
  final DateTime timestamp;
  final String content;
  final List<PlantModel> plants;
  final List<JournalPhotoModel> photos;
  final double? tempF;
  final double? humidityPct;
  final double? vpdKpa;
  final double? soilMoisturePct;
  final bool watered;
  final String nutrients;
  final List<NutrientLineItemModel> nutrientRows;
  final DateTime? createdAt;

  const JournalEntryFormInitialData({
    required this.entryId,
    required this.type,
    required this.timestamp,
    required this.content,
    required this.plants,
    required this.photos,
    required this.tempF,
    required this.humidityPct,
    required this.vpdKpa,
    required this.soilMoisturePct,
    required this.watered,
    required this.nutrients,
    required this.nutrientRows,
    required this.createdAt,
  });
}

class JournalEntrySaveRequest {
  final int? entryId;
  final EntryType type;
  final DateTime timestamp;
  final String content;
  final List<int> plantIds;
  final List<String> newImagePaths;
  final List<int> photoIdsToDelete;
  final double? tempF;
  final double? humidityPct;
  final double? vpdKpa;
  final double? soilMoisturePct;
  final bool watered;
  final String nutrients;
  final List<NutrientLineItemModel> nutrientRows;
  final DateTime? createdAt;
  final int? completesTodoId;

  const JournalEntrySaveRequest({
    required this.entryId,
    required this.type,
    required this.timestamp,
    required this.content,
    required this.plantIds,
    required this.newImagePaths,
    required this.photoIdsToDelete,
    required this.tempF,
    required this.humidityPct,
    required this.vpdKpa,
    required this.soilMoisturePct,
    required this.watered,
    required this.nutrients,
    required this.nutrientRows,
    required this.createdAt,
    required this.completesTodoId,
  });
}

class CurrentReading {
  final double? tempF;
  final double? humidityPct;
  final double? vpdKpa;
  final double? soilMoisturePct;
  final DateTime timestamp;
  final bool isFresh;

  const CurrentReading({
    required this.tempF,
    required this.humidityPct,
    required this.vpdKpa,
    required this.soilMoisturePct,
    required this.timestamp,
    required this.isFresh,
  });
}

class JournalEntryController {
  final JournalRepository _journal;
  final PlantsRepository _plants;
  final EnvironmentSnapshotsDao _snapshots;
  final TodoActions _todos;

  const JournalEntryController({
    required JournalRepository journal,
    required PlantsRepository plants,
    required EnvironmentSnapshotsDao snapshots,
    required TodoActions todos,
  })  : _journal = journal,
        _plants = plants,
        _snapshots = snapshots,
        _todos = todos;

  Future<PlantModel?> loadPlant(int plantId) async =>
      (await _plants.getPlantById(plantId))?.plant;

  Future<JournalEntryFormInitialData?> loadEntry(int entryId) async {
    final details = await _journal.getEntryById(entryId);
    if (details == null) return null;
    final e = details.entry;
    return JournalEntryFormInitialData(
      entryId: e.id,
      type: e.type,
      timestamp: e.timestamp,
      content: e.content ?? '',
      plants: details.plants,
      photos: details.photos,
      tempF: e.tempF,
      humidityPct: e.humidityPct,
      vpdKpa: e.vpdKpa,
      soilMoisturePct: e.soilMoisturePct,
      watered: e.watered,
      nutrients: e.nutrients ?? '',
      nutrientRows: details.nutrientRows,
      createdAt: e.createdAt,
    );
  }

  /// Latest stored reading for the grow space of the first linked plant (or
  /// the default space). Null when nothing has been recorded.
  Future<CurrentReading?> currentReading({
    required List<int> plantIds,
    DateTime? now,
  }) async {
    var growSpaceId = kDefaultGrowSpaceId;
    if (plantIds.isNotEmpty) {
      final plant = await _plants.getPlantById(plantIds.first);
      growSpaceId = plant?.plant.growSpaceId ?? kDefaultGrowSpaceId;
    }
    final snapshot = await _snapshots.getLatestForGrowSpace(growSpaceId);
    if (snapshot == null) return null;
    final age = (now ?? DateTime.now()).difference(snapshot.timestamp);
    return CurrentReading(
      tempF: snapshot.tempF,
      humidityPct: snapshot.rhPct,
      vpdKpa: snapshot.vpdKpa,
      soilMoisturePct: snapshot.soilMoisturePct,
      timestamp: snapshot.timestamp,
      isFresh: age <= environmentSnapshotFreshness,
    );
  }

  Future<int> save(JournalEntrySaveRequest request) async {
    final vpd = request.vpdKpa ??
        vpdKpaFromFahrenheit(request.tempF, request.humidityPct);
    final entryId = request.entryId;
    int savedId;
    if (entryId == null) {
      savedId = await _journal.createEntry(
        timestamp: request.timestamp,
        type: request.type,
        content: request.content,
        imagePaths: request.newImagePaths,
        plantIds: request.plantIds,
        tempF: sanitizeTemperatureF(request.tempF),
        humidityPct: sanitizeHumidityPct(request.humidityPct),
        vpdKpa: sanitizeVpdKpa(vpd),
        soilMoisturePct: sanitizeSoilMoisturePct(request.soilMoisturePct),
        watered: request.watered || request.type == EntryType.watering,
        nutrients: request.nutrients,
        nutrientRows: request.nutrientRows,
      );
    } else {
      await _journal.updateEntry(
        entry: JournalEntryModel(
          id: entryId,
          timestamp: request.timestamp,
          content: request.content,
          type: request.type,
          tempF: sanitizeTemperatureF(request.tempF),
          humidityPct: sanitizeHumidityPct(request.humidityPct),
          vpdKpa: sanitizeVpdKpa(vpd),
          soilMoisturePct: sanitizeSoilMoisturePct(request.soilMoisturePct),
          watered: request.watered || request.type == EntryType.watering,
          nutrients: request.nutrients,
          createdAt: request.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        newImagePaths: request.newImagePaths,
        photoIdsToDelete: request.photoIdsToDelete,
        plantIds: request.plantIds,
        nutrientRows: request.nutrientRows,
      );
      savedId = entryId;
    }
    final todoId = request.completesTodoId;
    if (todoId != null) {
      await _todos.completeTodoWithJournalEntry(todoId, savedId);
    }
    return savedId;
  }
}

final journalEntryControllerProvider = Provider<JournalEntryController>((ref) {
  return JournalEntryController(
    journal: ref.watch(journalRepositoryProvider),
    plants: ref.watch(plantsRepositoryProvider),
    snapshots: ref.watch(environmentSnapshotsDaoProvider),
    todos: ref.watch(todoActionsProvider),
  );
});
