import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../environment/domain/environment_range_evaluator.dart';
import '../../../environment/domain/focus_line_builder.dart';
import '../../../environment/domain/time_in_range_calculator.dart';
import '../../../environment/domain/tomato_stage_bands.dart';
import '../../../environment/presentation/providers/environment_providers.dart';
import '../../../home_assistant/presentation/providers/grow_spaces_providers.dart';
import '../../../home_assistant/presentation/providers/ha_providers.dart';
import '../../../plants/data/models/plant_with_variety.dart';
import '../../../plants/presentation/contracts/plants_screen_contract.dart';
import '../../../plants/presentation/providers/plants_providers.dart';
import '../contracts/today_contract.dart';

final selectedWindowProvider =
    StateProvider<ReadingWindow>((ref) => ReadingWindow.day);
final selectedTraceMetricProvider =
    StateProvider<EnvironmentMetric>((ref) => EnvironmentMetric.vpd);

final todayContractProvider = Provider<TodayContract>((ref) {
  final growSpaceId = ref.watch(effectiveGrowSpaceIdProvider);
  final spaces = ref.watch(growSpacesStreamProvider).valueOrNull ?? const [];
  final configured = ref.watch(haIsConfiguredProvider).valueOrNull ?? false;
  final latest = ref.watch(latestSnapshotProvider(growSpaceId)).valueOrNull;
  final evaluation = ref.watch(environmentEvaluationProvider(growSpaceId));
  final bands = ref.watch(stageBandsProvider(growSpaceId)).valueOrNull;
  final stage = ref.watch(growSpaceStageProvider(growSpaceId));
  final window = ref.watch(selectedWindowProvider);
  final traceMetric = ref.watch(selectedTraceMetricProvider);
  final tir = ref
      .watch(timeInRangeProvider((growSpaceId: growSpaceId, window: window)));
  final dayRows = ref
          .watch(
            readingWindowProvider(
              (growSpaceId: growSpaceId, window: ReadingWindow.day),
            ),
          )
          .valueOrNull ??
      const [];
  final plants = ref.watch(growActivePlantsProvider).valueOrNull ?? const [];
  final backfillRunning = ref.watch(haHistoryBackfillServiceProvider).isRunning;

  return buildTodayContract(
    growSpaceId: growSpaceId,
    spaces: spaces,
    configured: configured,
    latest: latest,
    evaluation: evaluation,
    bands: bands?.bands,
    bandsOverridden: bands?.hasOverride ?? false,
    stageLabel: stage?.displayName ??
        TomatoStageBands.labelFor(TomatoStageBands.fallbackKey),
    window: window,
    tir: tir,
    traceMetric: traceMetric,
    dayRows: dayRows,
    plants: plants,
    backfillRunning: backfillRunning,
  );
});

TodayContract buildTodayContract({
  required String growSpaceId,
  required List<GrowSpace> spaces,
  required bool configured,
  required EnvironmentSnapshot? latest,
  required EnvironmentEvaluation? evaluation,
  required ResolvedStageTargetBands? bands,
  required bool bandsOverridden,
  required String stageLabel,
  required ReadingWindow window,
  required TimeInRangeSet? tir,
  required EnvironmentMetric traceMetric,
  required List<EnvironmentSnapshot> dayRows,
  required List<PlantWithVariety> plants,
  required bool backfillRunning,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final space = spaces.where((s) => s.id == growSpaceId).firstOrNull;
  final state = !configured
      ? TodayState.unconfigured
      : latest == null
          ? TodayState.noReadings
          : TodayState.ready;
  final freshness = _freshness(latest, reference, backfillRunning);
  final focus = const FocusLineBuilder().build(
    evaluation: evaluation,
    stageLabel: stageLabel,
    configured: configured,
  );
  return TodayContract(
    state: state,
    growSpaceName: space?.name ?? 'My grow space',
    growSpaceId: growSpaceId,
    growSpaceChoices: [
      for (final s in spaces) GrowSpaceChoice(id: s.id, name: s.name),
    ],
    freshnessLabel: freshness.$1,
    freshnessTone: freshness.$2,
    stageLabel: stageLabel,
    bandsOverridden: bandsOverridden,
    readings: evaluation == null
        ? const []
        : [for (final m in evaluation.metrics) _tile(m)],
    focusLine: focus,
    selectedWindow: window,
    timeInRange: tir == null
        ? const []
        : [
            _tirTile('Temperature', tir.temperature),
            _tirTile('Humidity', tir.humidity),
            _tirTile('VPD', tir.vpd),
          ],
    trace:
        bands == null ? null : _trace(traceMetric, dayRows, bands, reference),
    traceMetric: traceMetric,
    plants: [
      for (final p in plants)
        if ((p.plant.growSpaceId ?? kDefaultGrowSpaceId) == growSpaceId)
          TodayPlantChip(
            id: p.plant.id,
            name: p.plant.name,
            stageLabel: p.plant.stage.displayName,
            dayLabel: plantAgeLabel(p.plant.startDate, now: reference),
          ),
    ],
    backfillRunning: backfillRunning,
  );
}

(String, StatusTone) _freshness(
  EnvironmentSnapshot? latest,
  DateTime now,
  bool backfill,
) {
  if (latest == null) return ('No readings yet', StatusTone.muted);
  final age = now.difference(latest.timestamp);
  if (age.inMinutes < 2) return ('Live · just now', StatusTone.good);
  if (age.inMinutes < 15) {
    return ('Live · ${age.inMinutes} min ago', StatusTone.good);
  }
  if (age.inHours < 2) {
    return ('Updated ${age.inMinutes} min ago', StatusTone.near);
  }
  final hours = age.inHours;
  final label = hours < 48 ? '$hours h ago' : '${age.inDays} days ago';
  return (
    backfill
        ? 'Last reading $label · catching up from Home Assistant'
        : 'Last reading $label',
    StatusTone.bad,
  );
}

ReadingTile _tile(MetricStatus m) {
  final value = m.value;
  final text = value == null
      ? '--'
      : switch (m.metric) {
          EnvironmentMetric.vpd => value.toStringAsFixed(2),
          _ => value.round().toString(),
        };
  String f(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(2);
  final (label, tone) = m.safetyBreach
      ? ('Unsafe', StatusTone.bad)
      : switch (m.status) {
          MetricRangeStatus.inRange => ('In range', StatusTone.good),
          MetricRangeStatus.nearLow => ('A bit low', StatusTone.near),
          MetricRangeStatus.nearHigh => ('A bit high', StatusTone.near),
          MetricRangeStatus.low => ('Low', StatusTone.bad),
          MetricRangeStatus.high => ('High', StatusTone.bad),
          MetricRangeStatus.unknown => ('No data', StatusTone.muted),
        };
  return ReadingTile(
    label: m.metric.label,
    valueText: text,
    unitText: m.metric.unit,
    statusLabel: label,
    tone: tone,
    bandText: '${f(m.band.min)}–${f(m.band.max)} ${m.metric.unit}',
  );
}

TimeInRangeTile _tirTile(String label, TimeInRangeResult r) {
  return TimeInRangeTile(
    label: label,
    pct: r.pct,
    coverageOk: r.coverageSufficient,
    coverageText: r.pct == null
        ? 'no readings'
        : '${(r.coveredFraction * 100).round()} % of window covered',
  );
}

TraceContract _trace(
  EnvironmentMetric metric,
  List<EnvironmentSnapshot> rows,
  ResolvedStageTargetBands bands,
  DateTime now,
) {
  double? pick(EnvironmentSnapshot r) => switch (metric) {
        EnvironmentMetric.temperature => r.tempF,
        EnvironmentMetric.humidity => r.rhPct,
        EnvironmentMetric.vpd => r.vpdKpa,
      };
  final band = switch (metric) {
    EnvironmentMetric.temperature => bands.temperatureF,
    EnvironmentMetric.humidity => bands.humidityPct,
    EnvironmentMetric.vpd => bands.vpdKpa,
  };
  return TraceContract(
    metric: metric,
    points: [
      for (final r in rows)
        if (pick(r) != null) TracePoint(r.timestamp, pick(r)!),
    ],
    bandMin: band.min,
    bandMax: band.max,
    windowStart: now.subtract(const Duration(hours: 24)),
    windowEnd: now,
  );
}
