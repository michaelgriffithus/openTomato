import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/environment_snapshots.dart';

part 'environment_snapshots_dao.g.dart';

@DriftAccessor(tables: [EnvironmentSnapshots])
class EnvironmentSnapshotsDao extends DatabaseAccessor<AppDatabase>
    with _$EnvironmentSnapshotsDaoMixin {
  EnvironmentSnapshotsDao(super.db);

  /// Inserts or replaces the reading at `(growSpaceId, timestamp)`.
  Future<int> upsertSnapshot({
    required String growSpaceId,
    required DateTime timestamp,
    required String source,
    double? tempF,
    double? rhPct,
    double? vpdKpa,
    double? upstreamVpdKpa,
    double? soilMoisturePct,
  }) {
    return into(environmentSnapshots).insert(
      EnvironmentSnapshotsCompanion.insert(
        growSpaceId: growSpaceId,
        timestamp: timestamp,
        source: source,
        tempF: Value(tempF),
        rhPct: Value(rhPct),
        vpdKpa: Value(vpdKpa),
        upstreamVpdKpa: Value(upstreamVpdKpa),
        soilMoisturePct: Value(soilMoisturePct),
      ),
      onConflict: DoUpdate(
        (old) => EnvironmentSnapshotsCompanion(
          tempF: Value(tempF),
          rhPct: Value(rhPct),
          vpdKpa: Value(vpdKpa),
          upstreamVpdKpa: Value(upstreamVpdKpa),
          soilMoisturePct: Value(soilMoisturePct),
          source: Value(source),
        ),
        target: [
          environmentSnapshots.growSpaceId,
          environmentSnapshots.timestamp,
        ],
      ),
    );
  }

  Future<EnvironmentSnapshot?> getLatestForGrowSpace(String growSpaceId) {
    return (select(environmentSnapshots)
          ..where((t) => t.growSpaceId.equals(growSpaceId))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<EnvironmentSnapshot?> watchLatestForGrowSpace(String growSpaceId) {
    return (select(environmentSnapshots)
          ..where((t) => t.growSpaceId.equals(growSpaceId))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<List<EnvironmentSnapshot>> getWindow({
    required String growSpaceId,
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) {
    return (select(environmentSnapshots)
          ..where(
            (t) =>
                t.growSpaceId.equals(growSpaceId) &
                t.timestamp.isBiggerOrEqualValue(fromInclusive) &
                t.timestamp.isSmallerOrEqualValue(toInclusive),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  Stream<List<EnvironmentSnapshot>> watchWindow({
    required String growSpaceId,
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) {
    return (select(environmentSnapshots)
          ..where(
            (t) =>
                t.growSpaceId.equals(growSpaceId) &
                t.timestamp.isBiggerOrEqualValue(fromInclusive) &
                t.timestamp.isSmallerOrEqualValue(toInclusive),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .watch();
  }

  /// Timestamps already stored in a window, so a backfill can skip them.
  Future<List<DateTime>> getTimestampsInWindow({
    required String growSpaceId,
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) async {
    final query = selectOnly(environmentSnapshots)
      ..addColumns([environmentSnapshots.timestamp])
      ..where(
        environmentSnapshots.growSpaceId.equals(growSpaceId) &
            environmentSnapshots.timestamp.isBiggerOrEqualValue(fromInclusive) &
            environmentSnapshots.timestamp.isSmallerOrEqualValue(toInclusive),
      );
    final rows = await query.get();
    return rows
        .map((row) => row.read(environmentSnapshots.timestamp)!)
        .toList(growable: false);
  }

  Future<int> deleteOlderThan(DateTime cutoff) {
    return (delete(environmentSnapshots)
          ..where((t) => t.timestamp.isSmallerThanValue(cutoff)))
        .go();
  }

  Future<int> deleteForGrowSpace(String growSpaceId) {
    return (delete(environmentSnapshots)
          ..where((t) => t.growSpaceId.equals(growSpaceId)))
        .go();
  }
}
