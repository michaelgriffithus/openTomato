import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/utils/environment_readings.dart';
import '../../../home_assistant/presentation/providers/grow_spaces_providers.dart';
import '../../../plants/domain/enums/growth_stage.dart';
import '../../../plants/presentation/providers/plants_providers.dart';
import '../../data/stage_target_resolver.dart';
import '../../data/stage_targets_settings_service.dart';
import '../../domain/environment_range_evaluator.dart';
import '../../domain/time_in_range_calculator.dart';

final stageTargetsSettingsServiceProvider =
    Provider<StageTargetsSettingsService>((ref) {
  return StageTargetsSettingsService(dao: ref.watch(appSettingsDaoProvider));
});

final stageTargetResolverProvider = Provider<StageTargetResolver>((ref) {
  return StageTargetResolver(
    growSpaces: ref.watch(growSpacesDaoProvider),
    appDefaults: ref.watch(stageTargetsSettingsServiceProvider),
  );
});

/// The grow space shown on Today. Null means the default grow space.
final selectedGrowSpaceIdProvider = StateProvider<String?>((ref) => null);

final effectiveGrowSpaceIdProvider = Provider<String>((ref) {
  final selected = ref.watch(selectedGrowSpaceIdProvider);
  final spaces = ref.watch(growSpacesStreamProvider).valueOrNull ?? const [];
  if (selected != null && spaces.any((s) => s.id == selected)) return selected;
  return kDefaultGrowSpaceId;
});

/// Newest stored reading for a grow space, regardless of age.
final latestSnapshotProvider =
    StreamProvider.family<EnvironmentSnapshot?, String>((ref, growSpaceId) {
  return ref
      .watch(environmentSnapshotsDaoProvider)
      .watchLatestForGrowSpace(growSpaceId);
});

/// Same, but null once older than the freshness window.
final currentReadingProvider =
    Provider.family<EnvironmentSnapshot?, String>((ref, growSpaceId) {
  final snapshot = ref.watch(latestSnapshotProvider(growSpaceId)).valueOrNull;
  if (snapshot == null) return null;
  final age = DateTime.now().difference(snapshot.timestamp);
  return age <= environmentSnapshotFreshness ? snapshot : null;
});

enum ReadingWindow {
  day(Duration(hours: 24), '24h'),
  week(Duration(days: 7), '7d');

  const ReadingWindow(this.duration, this.label);

  final Duration duration;
  final String label;
}

typedef WindowRequest = ({String growSpaceId, ReadingWindow window});

final readingWindowProvider =
    StreamProvider.family<List<EnvironmentSnapshot>, WindowRequest>((ref, req) {
  final now = DateTime.now();
  return ref.watch(environmentSnapshotsDaoProvider).watchWindow(
        growSpaceId: req.growSpaceId,
        fromInclusive: now.subtract(req.window.duration),
        toInclusive: now,
      );
});

/// The stage bands should follow: the most advanced grow-active plant in the
/// space, or the fallback band when none.
final growSpaceStageProvider =
    Provider.family<GrowthStage?, String>((ref, growSpaceId) {
  final plants = ref.watch(growActivePlantsProvider).valueOrNull ?? const [];
  GrowthStage? best;
  for (final p in plants) {
    final id = p.plant.growSpaceId ?? kDefaultGrowSpaceId;
    if (id != growSpaceId) continue;
    if (best == null || p.plant.stage.index > best.index) best = p.plant.stage;
  }
  return best;
});

final stageBandsProvider =
    FutureProvider.family<ResolvedEnvironmentTargets, String>(
        (ref, growSpaceId) {
  ref.watch(growSpacesStreamProvider);
  final stage = ref.watch(growSpaceStageProvider(growSpaceId));
  return ref.watch(stageTargetResolverProvider).resolve(
        growSpaceId: growSpaceId,
        stageKey: stage?.storageValue,
      );
});

final environmentEvaluationProvider =
    Provider.family<EnvironmentEvaluation?, String>((ref, growSpaceId) {
  final reading = ref.watch(currentReadingProvider(growSpaceId));
  final bands = ref.watch(stageBandsProvider(growSpaceId)).valueOrNull;
  if (bands == null) return null;
  return const EnvironmentRangeEvaluator().evaluate(
    tempF: reading?.tempF,
    rhPct: reading?.rhPct,
    vpdKpa: reading?.vpdKpa,
    bands: bands.bands,
  );
});

class TimeInRangeSet {
  final TimeInRangeResult temperature;
  final TimeInRangeResult humidity;
  final TimeInRangeResult vpd;

  const TimeInRangeSet({
    required this.temperature,
    required this.humidity,
    required this.vpd,
  });
}

final timeInRangeProvider =
    Provider.family<TimeInRangeSet?, WindowRequest>((ref, req) {
  final rows = ref.watch(readingWindowProvider(req)).valueOrNull;
  final bands = ref.watch(stageBandsProvider(req.growSpaceId)).valueOrNull;
  if (rows == null || bands == null) return null;
  final now = DateTime.now();
  final start = now.subtract(req.window.duration);
  const calc = TimeInRangeCalculator();
  List<TimedSample> samples(double? Function(EnvironmentSnapshot) pick) => [
        for (final row in rows)
          if (pick(row) != null) TimedSample(row.timestamp, pick(row)!),
      ];
  return TimeInRangeSet(
    temperature: calc.compute(
      samples: samples((r) => r.tempF),
      band: bands.bands.temperatureF,
      windowStart: start,
      windowEnd: now,
    ),
    humidity: calc.compute(
      samples: samples((r) => r.rhPct),
      band: bands.bands.humidityPct,
      windowStart: start,
      windowEnd: now,
    ),
    vpd: calc.compute(
      samples: samples((r) => r.vpdKpa),
      band: bands.bands.vpdKpa,
      windowStart: start,
      windowEnd: now,
    ),
  );
});
