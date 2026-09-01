import 'package:drift/drift.dart';

import '../../../features/plants/domain/enums/growth_stage.dart';
import '../../../features/plants/domain/services/grow_active_plant_filter.dart';
import '../database.dart';
import '../tables/plant_stage_history.dart';
import '../tables/plants.dart';
import '../tables/varieties.dart';

part 'plants_dao.g.dart';

class PlantWithVarietyEntity {
  final Plant plant;
  final Variety? variety;

  const PlantWithVarietyEntity({required this.plant, required this.variety});
}

@DriftAccessor(tables: [Plants, Varieties, PlantStageHistoryTable])
class PlantsDao extends DatabaseAccessor<AppDatabase> with _$PlantsDaoMixin {
  PlantsDao(super.db);

  JoinedSelectStatement<HasResultSet, dynamic> _joined() {
    return select(plants).join([
      leftOuterJoin(varieties, varieties.id.equalsExp(plants.varietyId)),
    ]);
  }

  PlantWithVarietyEntity _read(TypedResult row) {
    return PlantWithVarietyEntity(
      plant: row.readTable(plants),
      variety: row.readTableOrNull(varieties),
    );
  }

  Stream<List<PlantWithVarietyEntity>> watchActivePlants() {
    final query = _joined()
      ..where(plants.archivedAt.isNull())
      ..orderBy([OrderingTerm.asc(plants.name)]);
    return query.watch().map((rows) => rows.map(_read).toList());
  }

  Stream<List<PlantWithVarietyEntity>> watchGrowActivePlants() {
    final query = _joined()
      ..where(
        plants.archivedAt.isNull() &
            plants.currentStage.isNotIn(kExcludedGrowActiveStageNames),
      )
      ..orderBy([OrderingTerm.asc(plants.name)]);
    return query.watch().map((rows) => rows.map(_read).toList());
  }

  Future<List<PlantWithVarietyEntity>> getGrowActivePlants() async {
    final query = _joined()
      ..where(
        plants.archivedAt.isNull() &
            plants.currentStage.isNotIn(kExcludedGrowActiveStageNames),
      );
    final rows = await query.get();
    return rows.map(_read).toList();
  }

  Stream<List<PlantWithVarietyEntity>> watchArchivedPlants() {
    final query = _joined()
      ..where(plants.archivedAt.isNotNull())
      ..orderBy([OrderingTerm.desc(plants.archivedAt)]);
    return query.watch().map((rows) => rows.map(_read).toList());
  }

  Stream<PlantWithVarietyEntity?> watchPlantById(int id) {
    final query = _joined()..where(plants.id.equals(id));
    return query.watchSingleOrNull().map((r) => r == null ? null : _read(r));
  }

  Future<PlantWithVarietyEntity?> getPlantById(int id) async {
    final query = _joined()..where(plants.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _read(row);
  }

  Future<List<PlantWithVarietyEntity>> getPlantsByIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final query = _joined()..where(plants.id.isIn(ids));
    final rows = await query.get();
    return rows.map(_read).toList();
  }

  Future<int> insertPlant(PlantsCompanion plant) {
    return into(plants).insert(plant);
  }

  Future<bool> updatePlant(Plant plant) {
    return update(plants).replace(plant);
  }

  Future<int> updatePlantDetails({
    required int plantId,
    required String name,
    required int? varietyId,
    required DateTime startDate,
    required String startMethod,
    required String? growSpaceId,
    required String? location,
    required String? container,
    required String? medium,
    required String? notes,
  }) {
    return (update(plants)..where((p) => p.id.equals(plantId))).write(
      PlantsCompanion(
        name: Value(name),
        varietyId: Value(varietyId),
        startDate: Value(startDate),
        startMethod: Value(startMethod),
        growSpaceId: Value(growSpaceId),
        location: Value(location),
        container: Value(container),
        medium: Value(medium),
        notes: Value(notes),
      ),
    );
  }

  Future<int> updatePlantStage({
    required int plantId,
    required GrowthStage stage,
    required DateTime startedAt,
  }) {
    final clearArchive = stage.isGrowActive
        ? const Value<DateTime?>(null)
        : const Value<DateTime?>.absent();
    return (update(plants)..where((p) => p.id.equals(plantId))).write(
      PlantsCompanion(
        currentStage: Value(stage.storageValue),
        stageStartedAt: Value(startedAt),
        archivedAt: clearArchive,
      ),
    );
  }

  Future<int> updateHarvest({
    required int plantId,
    required DateTime? harvestedAt,
    required String? harvestNotes,
  }) {
    return (update(plants)..where((p) => p.id.equals(plantId))).write(
      PlantsCompanion(
        harvestedAt: Value(harvestedAt),
        harvestNotes: Value(harvestNotes),
      ),
    );
  }

  Stream<List<PlantStageHistory>> watchStageHistory(int plantId) {
    return (select(plantStageHistoryTable)
          ..where((row) => row.plantId.equals(plantId))
          ..orderBy([(row) => OrderingTerm.asc(row.movedAt)]))
        .watch();
  }

  Future<void> upsertStageHistory({
    required int plantId,
    required GrowthStage stage,
    required DateTime movedAt,
    int? expectedDurationDays,
  }) async {
    await into(plantStageHistoryTable).insertOnConflictUpdate(
      PlantStageHistoryTableCompanion.insert(
        plantId: plantId,
        stage: stage.storageValue,
        movedAt: movedAt,
        expectedDurationDays: Value(expectedDurationDays),
      ),
    );
  }

  Future<int> archivePlant(int id) {
    return (update(plants)..where((p) => p.id.equals(id)))
        .write(PlantsCompanion(archivedAt: Value(DateTime.now())));
  }

  Future<int> unarchivePlant(int id) {
    return (update(plants)..where((p) => p.id.equals(id)))
        .write(const PlantsCompanion(archivedAt: Value(null)));
  }

  Future<int> deletePlant(int id) {
    return (delete(plants)..where((p) => p.id.equals(id))).go();
  }
}
