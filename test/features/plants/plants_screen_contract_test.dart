import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/core/database/database.dart';
import 'package:open_tomato/features/plants/data/models/plant_with_variety.dart';
import 'package:open_tomato/features/plants/domain/enums/growth_stage.dart';
import 'package:open_tomato/features/plants/domain/enums/start_method.dart';
import 'package:open_tomato/features/plants/domain/models/plant_model.dart';
import 'package:open_tomato/features/plants/presentation/contracts/plants_screen_contract.dart';
import 'package:open_tomato/features/plants/presentation/widgets/plant_lifecycle_timeline.dart';

PlantWithVariety _plant(int id, {String? growSpaceId, DateTime? start}) {
  return PlantWithVariety(
    plant: PlantModel(
      id: id,
      name: 'Plant $id',
      varietyId: null,
      startDate: start ?? DateTime(2026, 8, 1),
      startMethod: StartMethod.seed,
      stage: GrowthStage.vegetative,
      stageStartedAt: null,
      growSpaceId: growSpaceId,
      location: null,
      container: null,
      medium: null,
      notes: null,
      harvestedAt: null,
      harvestNotes: null,
      createdAt: DateTime(2026, 8, 1),
      archivedAt: null,
    ),
    variety: null,
  );
}

void main() {
  final now = DateTime(2026, 9, 1);

  test('empty phase when nothing exists', () {
    final c = buildPlantsScreenContract(
      active: const [],
      archived: const [],
      entries: const [],
      growSpaces: const [],
    );
    expect(c.phase, PlantsScreenPhase.empty);
  });

  test('groups by grow space with the default first', () {
    final spaces = [
      GrowSpace(
        id: 'shelf',
        name: 'Seed shelf',
        isDefault: false,
        enabled: true,
        createdAt: now,
        updatedAt: now,
      ),
      GrowSpace(
        id: kDefaultGrowSpaceId,
        name: 'Greenhouse',
        isDefault: true,
        enabled: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final c = buildPlantsScreenContract(
      active: [
        _plant(1, growSpaceId: 'shelf'),
        _plant(2),
        _plant(3, growSpaceId: 'missing'),
      ],
      archived: const [],
      entries: const [],
      growSpaces: spaces,
      now: now,
    );
    expect(c.phase, PlantsScreenPhase.ready);
    expect(c.activeCount, 3);
    expect(c.groups.map((g) => g.growSpaceName), ['Greenhouse', 'Seed shelf']);
    expect(c.groups.first.plants.map((p) => p.id), [2, 3]);
    expect(c.groups.first.plants.first.varietyLabel, 'Unknown variety');
  });

  test('age labels', () {
    expect(plantAgeLabel(DateTime(2026, 9, 1), now: now), 'Started today');
    expect(plantAgeLabel(DateTime(2026, 8, 25), now: now), 'Day 7');
    expect(plantAgeLabel(DateTime(2026, 8, 4), now: now), '4 weeks');
    expect(plantAgeLabel(DateTime(2026, 8, 2), now: now), '4 weeks, 2 days');
    expect(plantAgeLabel(DateTime(2026, 9, 5), now: now), 'Starts soon');
  });

  test('lifecycle stages mark completed, current, upcoming', () {
    final stages = buildLifecycleStages(
      current: GrowthStage.fruitSet,
      movedAt: {GrowthStage.seedling: DateTime(2026, 6, 1)},
    );
    expect(stages.map((s) => s.stage), isNot(contains(GrowthStage.archived)));
    expect(stages[0].status, PlantLifecycleStageStatus.completed);
    expect(stages[3].status, PlantLifecycleStageStatus.current);
    expect(stages[4].status, PlantLifecycleStageStatus.upcoming);
    expect(stages[0].movedAt, DateTime(2026, 6, 1));
    expect(stages[1].movedAt, isNull);
  });
}
