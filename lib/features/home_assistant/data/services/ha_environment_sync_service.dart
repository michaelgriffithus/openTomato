import '../../../../core/database/database.dart';
import '../../../../core/utils/environment_readings.dart';
import '../models/ha_live_update_models.dart';
import 'ha_reading_normalizer.dart';

class HaHistoricalReading {
  final DateTime timestamp;
  final double? tempF;
  final double? humidityPct;
  final double? vpdKpa;

  const HaHistoricalReading({
    required this.timestamp,
    required this.tempF,
    required this.humidityPct,
    required this.vpdKpa,
  });
}

/// The single writer of `environment_snapshots`. Every path (live, poll,
/// backfill) sanitises the same way and recomputes VPD canonically; the
/// entity's own VPD is kept only as provenance.
class HaEnvironmentSyncService {
  final EnvironmentSnapshotsDao _snapshots;
  final HAReadingNormalizer _normalizer;

  const HaEnvironmentSyncService({
    required EnvironmentSnapshotsDao snapshots,
    HAReadingNormalizer normalizer = const HAReadingNormalizer(),
  })  : _snapshots = snapshots,
        _normalizer = normalizer;

  static const String sourceLive = 'ha_live';
  static const String sourcePoll = 'ha_poll';
  static const String sourceBackfill = 'ha_backfill';

  /// Writes one reading per grow space. Returns the ids written.
  Future<Set<String>> syncReadings({
    required DateTime timestamp,
    required Map<String, HALiveReading> readingsByGrowSpace,
    required String source,
  }) async {
    final written = <String>{};
    for (final entry in readingsByGrowSpace.entries) {
      final r = entry.value;
      final tempF = sanitizeTemperatureF(r.tempF);
      final humidity = sanitizeHumidityPct(r.humidityPct);
      final upstreamVpd = sanitizeVpdKpa(r.vpdKpa);
      final vpd = _normalizer.canonicalVpd(
        tempF: tempF,
        humidityPct: humidity,
        upstreamVpdKpa: upstreamVpd,
      );
      final soil = sanitizeSoilMoisturePct(r.soilMoisturePct);
      if (tempF == null && humidity == null && vpd == null && soil == null) {
        continue;
      }
      await _snapshots.upsertSnapshot(
        growSpaceId: entry.key,
        timestamp: timestamp,
        source: source,
        tempF: tempF,
        rhPct: humidity,
        vpdKpa: vpd,
        upstreamVpdKpa: upstreamVpd,
        soilMoisturePct: soil,
      );
      written.add(entry.key);
    }
    return written;
  }

  /// Catch-up writer for recorder history: many timestamped readings for one
  /// grow space in a single transaction. Returns the count written.
  Future<int> backfillHistoricalReadings({
    required String growSpaceId,
    required List<HaHistoricalReading> readings,
  }) async {
    if (readings.isEmpty) return 0;
    final usable =
        <({DateTime at, double? t, double? rh, double? vpd, double? up})>[];
    for (final reading in readings) {
      final tempF = sanitizeTemperatureF(reading.tempF);
      final humidity = sanitizeHumidityPct(reading.humidityPct);
      final upstreamVpd = sanitizeVpdKpa(reading.vpdKpa);
      final vpd = _normalizer.canonicalVpd(
        tempF: tempF,
        humidityPct: humidity,
        upstreamVpdKpa: upstreamVpd,
      );
      if (tempF == null && humidity == null && vpd == null) continue;
      usable.add(
        (
          at: reading.timestamp,
          t: tempF,
          rh: humidity,
          vpd: vpd,
          up: upstreamVpd
        ),
      );
    }
    if (usable.isEmpty) return 0;
    usable.sort((a, b) => a.at.compareTo(b.at));
    await _snapshots.attachedDatabase.transaction(() async {
      for (final r in usable) {
        await _snapshots.upsertSnapshot(
          growSpaceId: growSpaceId,
          timestamp: r.at,
          source: sourceBackfill,
          tempF: r.t,
          rhPct: r.rh,
          vpdKpa: r.vpd,
          upstreamVpdKpa: r.up,
        );
      }
    });
    return usable.length;
  }
}
