import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/core/database/database.dart';
import 'package:open_tomato/features/environment/domain/environment_range_evaluator.dart';
import 'package:open_tomato/features/environment/domain/tomato_stage_bands.dart';
import 'package:open_tomato/features/environment/presentation/providers/environment_providers.dart';
import 'package:open_tomato/features/today/presentation/contracts/today_contract.dart';
import 'package:open_tomato/features/today/presentation/providers/today_contract_provider.dart';

EnvironmentSnapshot _row(DateTime at, {double? t, double? rh, double? vpd}) =>
    EnvironmentSnapshot(
      id: at.millisecondsSinceEpoch,
      growSpaceId: 'default',
      timestamp: at,
      tempF: t,
      rhPct: rh,
      vpdKpa: vpd,
      source: 'ha_live',
      createdAt: at,
    );

void main() {
  final now = DateTime(2026, 9, 1, 12);
  final spaces = [
    GrowSpace(
      id: 'default',
      name: 'Greenhouse',
      isDefault: true,
      enabled: true,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  TodayContract build({
    bool configured = true,
    EnvironmentSnapshot? latest,
    bool backfill = false,
  }) {
    final bands = TomatoStageBands.vegetative;
    final fresh = latest != null &&
        now.difference(latest.timestamp) <= const Duration(hours: 2);
    final evaluation = !fresh
        ? null
        : const EnvironmentRangeEvaluator().evaluate(
            tempF: latest.tempF,
            rhPct: latest.rhPct,
            vpdKpa: latest.vpdKpa,
            bands: bands,
          );
    return buildTodayContract(
      growSpaceId: 'default',
      spaces: spaces,
      configured: configured,
      latest: latest,
      evaluation: evaluation,
      bands: bands,
      bandsOverridden: false,
      stageLabel: 'Vegetative',
      window: ReadingWindow.day,
      tir: null,
      traceMetric: EnvironmentMetric.vpd,
      dayRows: latest == null ? const [] : [latest],
      plants: const [],
      backfillRunning: backfill,
      now: now,
    );
  }

  test('unconfigured', () {
    final c = build(configured: false);
    expect(c.state, TodayState.unconfigured);
    expect(c.focusLine, 'Connect Home Assistant to see readings.');
    expect(c.growSpaceName, 'Greenhouse');
  });

  test('no readings yet', () {
    final c = build();
    expect(c.state, TodayState.noReadings);
    expect(c.freshnessLabel, 'No readings yet');
    expect(c.freshnessTone, StatusTone.muted);
  });

  test('live reading tiles and status labels', () {
    final c = build(
      latest: _row(
        now.subtract(const Duration(minutes: 1)),
        t: 75,
        rh: 76,
        vpd: 1.0,
      ),
    );
    expect(c.state, TodayState.ready);
    expect(c.freshnessLabel, 'Live · just now');
    expect(
      c.readings.map((r) => r.statusLabel).toList(),
      ['In range', 'High', 'In range'],
    );
    expect(c.readings[1].tone, StatusTone.bad);
    expect(c.readings[2].valueText, '1.00');
    expect(c.readings[0].bandText, '70–82 °F');
    expect(c.focusLine, contains('Humidity 76 % is above the 55–70 % band.'));
    expect(c.trace!.points.length, 1);
    expect(c.trace!.bandMin, 0.8);
  });

  test('stale reading with backfill running says catching up', () {
    final c = build(
      latest: _row(
        now.subtract(const Duration(hours: 5)),
        t: 75,
        rh: 60,
        vpd: 1.0,
      ),
      backfill: true,
    );
    expect(
      c.freshnessLabel,
      'Last reading 5 h ago · catching up from Home Assistant',
    );
    expect(c.freshnessTone, StatusTone.bad);
    expect(
      c.readings,
      isEmpty,
      reason: 'no evaluation without a fresh reading',
    );
  });
}
