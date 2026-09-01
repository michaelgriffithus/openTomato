import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/features/plants/domain/enums/growth_stage.dart';
import 'package:open_tomato/features/plants/domain/services/grow_active_plant_filter.dart';
import 'package:open_tomato/features/plants/domain/services/stage_progress.dart';

void main() {
  test('storage values round-trip and never collide', () {
    final values = GrowthStage.values.map((s) => s.storageValue).toSet();
    expect(values.length, GrowthStage.values.length);
    for (final stage in GrowthStage.values) {
      expect(GrowthStage.fromStorage(stage.storageValue), stage);
    }
    expect(GrowthStage.fromStorage('nonsense'), GrowthStage.seedling);
  });

  test('only done and archived are excluded from grow-active', () {
    expect(kExcludedGrowActiveStageNames, ['done', 'archived']);
    expect(GrowthStage.selectable, isNot(contains(GrowthStage.archived)));
    expect(GrowthStage.selectable, contains(GrowthStage.done));
  });

  test('stage progress counts calendar days', () {
    final now = DateTime(2026, 9, 1, 15);
    final p = stageProgress(
      startDate: DateTime(2026, 8, 1, 9),
      stageStartedAt: DateTime(2026, 8, 25, 23),
      daysToMaturity: 62,
      now: now,
    );
    expect(p.daysSinceStart, 31);
    expect(p.daysInStage, 7);
    expect(p.daysToExpectedMaturity, 31);
    expect(p.maturityFraction, closeTo(0.5, 0.001));
  });

  test('stage progress tolerates missing data', () {
    final p = stageProgress(
      startDate: null,
      stageStartedAt: null,
      daysToMaturity: null,
    );
    expect(p.daysSinceStart, isNull);
    expect(p.daysInStage, isNull);
    expect(p.maturityFraction, isNull);
  });
}
