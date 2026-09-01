import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/grow_space_stage_targets.dart';
import '../tables/grow_spaces.dart';

part 'grow_spaces_dao.g.dart';

@DriftAccessor(tables: [GrowSpaces, GrowSpaceStageTargets])
class GrowSpacesDao extends DatabaseAccessor<AppDatabase>
    with _$GrowSpacesDaoMixin {
  GrowSpacesDao(super.db);

  Future<List<GrowSpace>> getAllGrowSpaces() {
    return (select(growSpaces)
          ..orderBy([
            (t) => OrderingTerm.desc(t.isDefault),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
  }

  Stream<List<GrowSpace>> watchAllGrowSpaces() {
    return (select(growSpaces)
          ..orderBy([
            (t) => OrderingTerm.desc(t.isDefault),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }

  Future<List<GrowSpace>> getEnabledGrowSpaces() {
    return (select(growSpaces)
          ..where((t) => t.enabled.equals(true))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isDefault),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
  }

  Future<GrowSpace?> getGrowSpaceById(String id) {
    return (select(growSpaces)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<GrowSpace?> watchGrowSpaceById(String id) {
    return (select(growSpaces)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// The default grow space, resolved by its reserved id. The id is the
  /// identity; the `isDefault` flag is display state that follows it.
  Future<GrowSpace?> getDefaultGrowSpace() {
    return (select(growSpaces)..where((t) => t.id.equals(kDefaultGrowSpaceId)))
        .getSingleOrNull();
  }

  /// Insert-or-replace. Callers must pass EVERY column they want to keep: a
  /// partial companion resets unspecified columns to their defaults.
  Future<void> upsertGrowSpace(GrowSpacesCompanion companion) {
    return into(growSpaces).insert(
      companion,
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Partial update that never clobbers other columns.
  Future<int> writeGrowSpace(String id, GrowSpacesCompanion companion) {
    return (update(growSpaces)..where((t) => t.id.equals(id))).write(companion);
  }

  Future<void> deleteGrowSpace(String id) {
    return (delete(growSpaces)..where((t) => t.id.equals(id))).go();
  }

  Future<int> setGrowSpaceEnabled(String id, bool enabled) {
    return (update(growSpaces)..where((t) => t.id.equals(id))).write(
      GrowSpacesCompanion(
        enabled: Value(enabled),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<GrowSpaceStageTarget>> getStageTargetsForGrowSpace(
    String growSpaceId,
  ) {
    return (select(growSpaceStageTargets)
          ..where((t) => t.growSpaceId.equals(growSpaceId))
          ..orderBy([(t) => OrderingTerm.asc(t.stageKey)]))
        .get();
  }

  Future<void> upsertStageTarget(GrowSpaceStageTargetsCompanion companion) {
    return into(growSpaceStageTargets).insert(
      companion,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteStageTargetsForGrowSpace(String growSpaceId) {
    return (delete(growSpaceStageTargets)
          ..where((t) => t.growSpaceId.equals(growSpaceId)))
        .go();
  }

  Future<void> deleteStageTarget(String growSpaceId, String stageKey) {
    return (delete(growSpaceStageTargets)
          ..where(
            (t) =>
                t.growSpaceId.equals(growSpaceId) & t.stageKey.equals(stageKey),
          ))
        .go();
  }
}
