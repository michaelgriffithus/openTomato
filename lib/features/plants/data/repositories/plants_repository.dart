import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../journal/domain/enums/entry_type.dart';
import '../../domain/enums/growth_stage.dart';
import '../../domain/enums/start_method.dart';
import '../mappers/plant_domain_mappers.dart';
import '../models/plant_with_variety.dart';

class PlantsRepository {
  final PlantsDao _dao;

  /// When present, [createPlant] and [updatePlantStage] also write journal
  /// milestones so the plant appears on the Timeline. Optional so read-only
  /// call sites keep single-argument construction.
  final JournalEntriesDao? _journalDao;

  PlantsRepository(this._dao, {JournalEntriesDao? journalDao})
      : _journalDao = journalDao;

  Stream<List<PlantWithVariety>> watchActivePlants() => _dao
      .watchActivePlants()
      .map((rows) => rows.map((row) => row.toDomain()).toList());

  Stream<List<PlantWithVariety>> watchGrowActivePlants() => _dao
      .watchGrowActivePlants()
      .map((rows) => rows.map((row) => row.toDomain()).toList());

  Future<List<PlantWithVariety>> getGrowActivePlants() async =>
      (await _dao.getGrowActivePlants()).map((row) => row.toDomain()).toList();

  Stream<List<PlantWithVariety>> watchArchivedPlants() => _dao
      .watchArchivedPlants()
      .map((rows) => rows.map((row) => row.toDomain()).toList());

  Stream<PlantWithVariety?> watchPlantById(int id) =>
      _dao.watchPlantById(id).map((row) => row?.toDomain());

  Future<PlantWithVariety?> getPlantById(int id) async =>
      (await _dao.getPlantById(id))?.toDomain();

  Future<List<PlantWithVariety>> getPlantsByIds(List<int> ids) async =>
      (await _dao.getPlantsByIds(ids)).map((row) => row.toDomain()).toList();

  Future<int> createPlant({
    required String name,
    required int? varietyId,
    required DateTime startDate,
    required StartMethod startMethod,
    String? growSpaceId,
    String? location,
    String? container,
    String? medium,
    String? notes,
  }) async {
    final plantId = await _dao.insertPlant(
      PlantsCompanion.insert(
        name: name.trim(),
        varietyId: Value(varietyId),
        startDate: startDate,
        startMethod: Value(startMethod.storageValue),
        currentStage: GrowthStage.seedling.storageValue,
        stageStartedAt: Value(startDate),
        growSpaceId: Value(growSpaceId),
        location: Value(location),
        container: Value(container),
        medium: Value(medium),
        notes: Value(notes),
      ),
    );
    await _dao.upsertStageHistory(
      plantId: plantId,
      stage: GrowthStage.seedling,
      movedAt: startDate,
    );
    await _recordMilestone(
      plantId: plantId,
      at: startDate,
      content: 'Started growing ${name.trim()}.',
      entryType: EntryType.stageChange,
    );
    return plantId;
  }

  /// Best-effort: a journaling failure never fails the plant write.
  Future<void> _recordMilestone({
    required int plantId,
    required DateTime at,
    required String content,
    required EntryType entryType,
  }) async {
    final journalDao = _journalDao;
    if (journalDao == null) return;
    try {
      final entryId = await journalDao.insertEntry(
        JournalEntriesCompanion.insert(
          timestamp: at,
          content: Value(content),
          entryType: Value(entryType.storageValue),
        ),
      );
      await journalDao.associatePlant(entryId, plantId);
    } catch (_) {
      // Timeline seeding is non-critical.
    }
  }

  Future<void> updatePlantDetails({
    required int plantId,
    required String name,
    required int? varietyId,
    required DateTime startDate,
    required StartMethod startMethod,
    required String? growSpaceId,
    required String? location,
    required String? container,
    required String? medium,
    required String? notes,
  }) async {
    await _dao.updatePlantDetails(
      plantId: plantId,
      name: name.trim(),
      varietyId: varietyId,
      startDate: startDate,
      startMethod: startMethod.storageValue,
      growSpaceId: growSpaceId,
      location: location,
      container: container,
      medium: medium,
      notes: notes,
    );
  }

  Future<void> updatePlantStage({
    required int plantId,
    required GrowthStage stage,
    DateTime? startedAt,
    String? plantName,
  }) async {
    final movedAt = startedAt ?? DateTime.now();
    await _dao.updatePlantStage(
      plantId: plantId,
      stage: stage,
      startedAt: movedAt,
    );
    await _dao.upsertStageHistory(
      plantId: plantId,
      stage: stage,
      movedAt: movedAt,
    );
    if (stage == GrowthStage.done) {
      await _dao.archivePlant(plantId);
    }
    await _recordMilestone(
      plantId: plantId,
      at: movedAt,
      content: '${plantName ?? 'Plant'} moved to ${stage.displayName}.',
      entryType: EntryType.stageChange,
    );
  }

  Future<void> recordHarvest({
    required int plantId,
    required DateTime harvestedAt,
    required String? notes,
    String? plantName,
  }) async {
    await _dao.updateHarvest(
      plantId: plantId,
      harvestedAt: harvestedAt,
      harvestNotes: notes,
    );
    await _recordMilestone(
      plantId: plantId,
      at: harvestedAt,
      content: notes == null || notes.trim().isEmpty
          ? 'Harvested ${plantName ?? 'plant'}.'
          : 'Harvested ${plantName ?? 'plant'}: ${notes.trim()}',
      entryType: EntryType.harvest,
    );
  }

  Stream<List<PlantStageHistory>> watchStageHistory(int plantId) =>
      _dao.watchStageHistory(plantId);

  Future<void> archivePlant(int id) => _dao.archivePlant(id);

  Future<void> unarchivePlant(int id) => _dao.unarchivePlant(id);

  Future<void> deletePlant(int id) => _dao.deletePlant(id);
}

final plantsRepositoryProvider = Provider<PlantsRepository>((ref) {
  return PlantsRepository(
    ref.watch(plantsDaoProvider),
    journalDao: ref.watch(journalEntriesDaoProvider),
  );
});
