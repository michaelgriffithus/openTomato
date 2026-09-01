import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/core/database/database.dart';
import 'package:open_tomato/features/plants/data/repositories/plants_repository.dart';
import 'package:open_tomato/features/plants/domain/enums/growth_stage.dart';
import 'package:open_tomato/features/plants/domain/enums/start_method.dart';

void main() {
  late AppDatabase db;
  late PlantsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PlantsRepository(db.plantsDao, journalDao: db.journalEntriesDao);
  });

  tearDown(() => db.close());

  test('createPlant seeds stage history and a journal milestone', () async {
    final start = DateTime(2026, 8, 1);
    final id = await repo.createPlant(
      name: '  Sungold  ',
      varietyId: null,
      startDate: start,
      startMethod: StartMethod.transplant,
    );
    final plant = await repo.getPlantById(id);
    expect(plant!.plant.name, 'Sungold');
    expect(plant.plant.stage, GrowthStage.seedling);
    expect(plant.plant.startMethod, StartMethod.transplant);
    expect(plant.variety, isNull);

    final history = await repo.watchStageHistory(id).first;
    expect(history.single.stage, 'seedling');
    expect(history.single.movedAt, start);

    final entries = await db.journalEntriesDao.watchEntriesForPlant(id).first;
    expect(entries.single.entry.entryType, 'stage_change');
    expect(entries.single.entry.content, 'Started growing Sungold.');
  });

  test('updatePlantStage records history, milestone, and archives on done',
      () async {
    final id = await repo.createPlant(
      name: 'Roma',
      varietyId: null,
      startDate: DateTime(2026, 7, 1),
      startMethod: StartMethod.seed,
    );
    await repo.updatePlantStage(
      plantId: id,
      stage: GrowthStage.flowering,
      startedAt: DateTime(2026, 8, 1),
      plantName: 'Roma',
    );
    var plant = await repo.getPlantById(id);
    expect(plant!.plant.stage, GrowthStage.flowering);
    expect(plant.plant.isArchived, isFalse);

    await repo.updatePlantStage(plantId: id, stage: GrowthStage.done);
    plant = await repo.getPlantById(id);
    expect(plant!.plant.isArchived, isTrue);
    expect(await repo.watchActivePlants().first, isEmpty);
    expect((await repo.watchArchivedPlants().first).single.plant.id, id);

    // Moving back to a grow-active stage clears the archive flag.
    await repo.updatePlantStage(plantId: id, stage: GrowthStage.harvesting);
    plant = await repo.getPlantById(id);
    expect(plant!.plant.isArchived, isFalse);

    final history = await repo.watchStageHistory(id).first;
    expect(
      history.map((h) => h.stage),
      containsAll(['seedling', 'flowering', 'done', 'harvesting']),
    );
  });

  test('grow-active list excludes done plants but keeps harvesting', () async {
    final a = await repo.createPlant(
      name: 'A',
      varietyId: null,
      startDate: DateTime(2026, 7, 1),
      startMethod: StartMethod.seed,
    );
    final b = await repo.createPlant(
      name: 'B',
      varietyId: null,
      startDate: DateTime(2026, 7, 1),
      startMethod: StartMethod.seed,
    );
    await repo.updatePlantStage(plantId: a, stage: GrowthStage.harvesting);
    await repo.updatePlantStage(plantId: b, stage: GrowthStage.done);
    await repo.unarchivePlant(b);
    final active = await repo.watchGrowActivePlants().first;
    expect(active.map((p) => p.plant.id), [a]);
  });

  test('recordHarvest writes date, notes, and a harvest entry', () async {
    final id = await repo.createPlant(
      name: 'Big Beef',
      varietyId: null,
      startDate: DateTime(2026, 6, 1),
      startMethod: StartMethod.seed,
    );
    await repo.recordHarvest(
      plantId: id,
      harvestedAt: DateTime(2026, 8, 20),
      notes: 'first two',
      plantName: 'Big Beef',
    );
    final plant = await repo.getPlantById(id);
    expect(plant!.plant.harvestedAt, DateTime(2026, 8, 20));
    expect(plant.plant.harvestNotes, 'first two');
    final entries = await db.journalEntriesDao.watchEntriesForPlant(id).first;
    expect(entries.any((e) => e.entry.entryType == 'harvest'), isTrue);
  });

  test('deleting a variety leaves the plant with a null variety', () async {
    final vId = await db.varietiesDao.insertVariety(
      VarietiesCompanion.insert(
        name: 'Test',
        growthHabit: 'dwarf',
        category: 'cherry',
      ),
    );
    final id = await repo.createPlant(
      name: 'P',
      varietyId: vId,
      startDate: DateTime(2026, 7, 1),
      startMethod: StartMethod.seed,
    );
    expect((await repo.getPlantById(id))!.variety!.name, 'Test');
    await db.varietiesDao.deleteVariety(vId);
    expect((await repo.getPlantById(id))!.variety, isNull);
  });
}
