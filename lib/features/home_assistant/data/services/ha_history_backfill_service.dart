import 'package:flutter/foundation.dart';

import '../../../../core/database/database.dart';
import '../../domain/exceptions/ha_exceptions.dart';
import '../repositories/grow_spaces_repository.dart';
import '../repositories/ha_settings_repository.dart';
import 'ha_environment_sync_service.dart';
import 'ha_history_service.dart';
import 'ha_reading_normalizer.dart';

typedef HaHistorySeriesLoader = Future<List<HaHistoryPoint>> Function({
  required String entityId,
  required DateTime from,
  required DateTime to,
  required String field,
});

/// Fills `environment_snapshots` gaps from Home Assistant's recorder.
///
/// The live paths only sample while the app is awake, so the phone is the
/// recorder. On each foreground this fetches the gap since the last stored
/// reading (72 h at most) and stores five-minute bucket averages, which sit
/// well inside the time-in-range calculator's 90-minute carry.
class HaHistoryBackfillService {
  static const Duration maxLookback = Duration(hours: 72);
  static const Duration minGap = Duration(minutes: 15);
  static const Duration bucket = Duration(minutes: 5);
  static const Duration minRunInterval = Duration(minutes: 15);
  static const List<String> _airFields = [
    HAReadingNormalizer.temperature,
    HAReadingNormalizer.humidity,
    HAReadingNormalizer.vpd,
  ];

  final EnvironmentSnapshotsDao _snapshots;
  final HASettingsRepository _settings;
  final GrowSpacesRepository _growSpaces;
  final HaEnvironmentSyncService _sync;
  final HaHistorySeriesLoader _seriesLoader;
  final DateTime Function() _now;

  bool _running = false;
  DateTime? _lastRunAt;
  bool _lastPassHadFetchFailures = false;

  bool get isRunning => _running;

  HaHistoryBackfillService({
    required EnvironmentSnapshotsDao snapshots,
    required HASettingsRepository settings,
    required GrowSpacesRepository growSpaces,
    required HaEnvironmentSyncService sync,
    HaHistoryService? historyService,
    HaHistorySeriesLoader? seriesLoader,
    DateTime Function()? now,
  })  : assert(historyService != null || seriesLoader != null),
        _snapshots = snapshots,
        _settings = settings,
        _growSpaces = growSpaces,
        _sync = sync,
        _seriesLoader = seriesLoader ??
            (({
              required entityId,
              required from,
              required to,
              required field,
            }) =>
                historyService!.getEntityHistorySeries(
                  entityId: entityId,
                  from: from,
                  to: to,
                  field: field,
                )),
        _now = now ?? DateTime.now;

  /// Runs when Home Assistant is configured and the throttle has passed.
  /// Deliberately no lastSuccessfulConnection gate. Returns rows written.
  Future<int> runIfEligible() async {
    if (_running) return 0;
    final now = _now();
    final lastRunAt = _lastRunAt;
    if (lastRunAt != null && now.difference(lastRunAt) < minRunInterval) {
      return 0;
    }
    // Claim the run before the first await: the post-frame callback and the
    // resumed lifecycle event both call this at launch, and two passes that
    // interleave here would each fetch the whole window.
    _running = true;
    try {
      final settings = await _settings.getSettings();
      if (settings == null || !settings.isEnabled) return 0;
      final token = await _settings.getAccessToken();
      if (token == null || token.isEmpty) return 0;

      _lastRunAt = now;
      _lastPassHadFetchFailures = false;
      var written = 0;
      for (final space in await _growSpaces.getEnabledGrowSpaces()) {
        written += await _backfillGrowSpace(
          growSpaceId: space.id,
          mappings: await _growSpaces.getMappings(space.id),
          now: now,
        );
      }
      // A pass that wrote nothing because every fetch failed (cold launch
      // racing the network) must not burn the throttle window.
      if (written == 0 && _lastPassHadFetchFailures) _lastRunAt = null;
      debugPrint('HA history backfill wrote $written snapshots');
      return written;
    } finally {
      _running = false;
    }
  }

  /// Where a pass starts fetching. Normally the second after the newest
  /// stored row. When the stored rows do not reach the start of the lookback
  /// window (a fresh mapping, where the live path has already written a
  /// minute-old reading), start at [earliest] instead so the first pass fills
  /// the whole window rather than treating that live row as "caught up".
  /// Rows already stored are upserted by timestamp, so refetching is safe.
  Future<DateTime> _fetchStart(
    String growSpaceId, {
    required DateTime earliest,
    required DateTime now,
  }) async {
    final latestStored = await _snapshots.getLatestForGrowSpace(growSpaceId);
    if (latestStored == null) return earliest;
    final stored = await _snapshots.getTimestampsInWindow(
      growSpaceId: growSpaceId,
      fromInclusive: earliest,
      toInclusive: now,
    );
    DateTime? oldest;
    for (final t in stored) {
      if (oldest == null || t.isBefore(oldest)) oldest = t;
    }
    if (oldest == null || oldest.difference(earliest) >= minGap) {
      return earliest;
    }
    final from = latestStored.timestamp.add(const Duration(seconds: 1));
    return from.isBefore(earliest) ? earliest : from;
  }

  Future<int> _backfillGrowSpace({
    required String growSpaceId,
    required Map<String, String> mappings,
    required DateTime now,
  }) async {
    final airEntities = {
      for (final field in _airFields)
        if (mappings[field]?.trim().isNotEmpty ?? false)
          field: mappings[field]!,
    };
    if (airEntities.isEmpty) return 0;

    final earliest = now.subtract(maxLookback);
    final from = await _fetchStart(growSpaceId, earliest: earliest, now: now);
    if (now.difference(from) < minGap) return 0;

    final samplesByField = <String, List<HaHistoryPoint>>{};
    for (final entry in airEntities.entries) {
      try {
        final series = await _seriesLoader(
          entityId: entry.value,
          from: from,
          to: now,
          field: entry.key,
        );
        if (series.isNotEmpty) samplesByField[entry.key] = series;
      } on HAException catch (error) {
        _lastPassHadFetchFailures = true;
        debugPrint(
          'HA backfill skipped $growSpaceId/${entry.key}: ${error.message}',
        );
      } on Exception catch (error) {
        _lastPassHadFetchFailures = true;
        debugPrint('HA backfill skipped $growSpaceId/${entry.key}: $error');
      }
    }
    if (samplesByField.isEmpty) return 0;
    final readings = bucketize(samplesByField);
    if (readings.isEmpty) return 0;
    return _sync.backfillHistoricalReadings(
      growSpaceId: growSpaceId,
      readings: readings,
    );
  }

  /// Averages each field within five-minute buckets.
  static List<HaHistoricalReading> bucketize(
    Map<String, List<HaHistoryPoint>> samplesByField,
  ) {
    final bucketMs = bucket.inMilliseconds;
    final accumulators = <int, Map<String, ({double sum, int count})>>{};
    samplesByField.forEach((field, points) {
      for (final point in points) {
        final start =
            point.timestamp.millisecondsSinceEpoch ~/ bucketMs * bucketMs;
        final byField = accumulators.putIfAbsent(start, () => {});
        final current = byField[field];
        byField[field] = current == null
            ? (sum: point.value, count: 1)
            : (sum: current.sum + point.value, count: current.count + 1);
      }
    });
    final readings = <HaHistoricalReading>[
      for (final entry in accumulators.entries)
        HaHistoricalReading(
          timestamp: DateTime.fromMillisecondsSinceEpoch(entry.key),
          tempF: _mean(entry.value[HAReadingNormalizer.temperature]),
          humidityPct: _mean(entry.value[HAReadingNormalizer.humidity]),
          vpdKpa: _mean(entry.value[HAReadingNormalizer.vpd]),
        ),
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return readings;
  }

  static double? _mean(({double sum, int count})? acc) =>
      acc == null ? null : acc.sum / acc.count;
}
