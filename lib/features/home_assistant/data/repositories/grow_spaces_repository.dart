import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../services/ha_reading_normalizer.dart';

class GrowSpaceStageTargetDraft {
  final String stageKey;
  final double? tempMinF;
  final double? tempMaxF;
  final double? humidityMinPct;
  final double? humidityMaxPct;
  final double? vpdMinKpa;
  final double? vpdMaxKpa;

  const GrowSpaceStageTargetDraft({
    required this.stageKey,
    this.tempMinF,
    this.tempMaxF,
    this.humidityMinPct,
    this.humidityMaxPct,
    this.vpdMinKpa,
    this.vpdMaxKpa,
  });

  bool get isEmpty =>
      tempMinF == null &&
      tempMaxF == null &&
      humidityMinPct == null &&
      humidityMaxPct == null &&
      vpdMinKpa == null &&
      vpdMaxKpa == null;
}

class GrowSpacesRepository {
  final GrowSpacesDao _dao;

  const GrowSpacesRepository(this._dao);

  Stream<List<GrowSpace>> watchGrowSpaces() => _dao.watchAllGrowSpaces();

  Future<List<GrowSpace>> getGrowSpaces() => _dao.getAllGrowSpaces();

  Future<List<GrowSpace>> getEnabledGrowSpaces() => _dao.getEnabledGrowSpaces();

  Future<GrowSpace?> getById(String id) => _dao.getGrowSpaceById(id);

  Future<GrowSpace> getDefault() async {
    final existing = await _dao.getDefaultGrowSpace();
    if (existing != null) return existing;
    final now = DateTime.now();
    await _dao.upsertGrowSpace(
      GrowSpacesCompanion.insert(
        id: kDefaultGrowSpaceId,
        name: 'My grow space',
        isDefault: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return (await _dao.getDefaultGrowSpace())!;
  }

  Future<String> create({
    required String name,
    String? tempEntityId,
    String? humidityEntityId,
    String? vpdEntityId,
    String? soilMoistureEntityId,
  }) async {
    await _assertNameIsFree(name);
    final id = 'gs_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    await _dao.upsertGrowSpace(
      GrowSpacesCompanion.insert(
        id: id,
        name: name.trim(),
        tempEntityId: Value(_clean(tempEntityId)),
        humidityEntityId: Value(_clean(humidityEntityId)),
        vpdEntityId: Value(_clean(vpdEntityId)),
        soilMoistureEntityId: Value(_clean(soilMoistureEntityId)),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  /// Partial write: only the fields this form owns. Flags such as `enabled`
  /// and `isDefault` are untouched.
  Future<void> update({
    required String id,
    required String name,
    String? tempEntityId,
    String? humidityEntityId,
    String? vpdEntityId,
    String? soilMoistureEntityId,
  }) async {
    final existing = await _dao.getGrowSpaceById(id);
    if (existing == null) throw StateError('Grow space not found: $id');
    await _assertNameIsFree(name, exceptId: id);
    await _dao.writeGrowSpace(
      id,
      GrowSpacesCompanion(
        name: Value(name.trim()),
        tempEntityId: Value(_clean(tempEntityId)),
        humidityEntityId: Value(_clean(humidityEntityId)),
        vpdEntityId: Value(_clean(vpdEntityId)),
        soilMoistureEntityId: Value(_clean(soilMoistureEntityId)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final affected = await _dao.setGrowSpaceEnabled(id, enabled);
    if (affected == 0) throw StateError('Grow space not found: $id');
  }

  Future<void> delete(String id) async {
    if (id == kDefaultGrowSpaceId) {
      throw StateError('The default grow space cannot be deleted.');
    }
    await _dao.deleteStageTargetsForGrowSpace(id);
    await _dao.deleteGrowSpace(id);
  }

  /// Field key → entity id for every mapped slot.
  Future<Map<String, String>> getMappings(String growSpaceId) async {
    final space = await _dao.getGrowSpaceById(growSpaceId);
    if (space == null) return const {};
    return {
      if (_valid(space.tempEntityId))
        HAReadingNormalizer.temperature: space.tempEntityId!.trim(),
      if (_valid(space.humidityEntityId))
        HAReadingNormalizer.humidity: space.humidityEntityId!.trim(),
      if (_valid(space.vpdEntityId))
        HAReadingNormalizer.vpd: space.vpdEntityId!.trim(),
      if (_valid(space.soilMoistureEntityId))
        HAReadingNormalizer.soilMoisture: space.soilMoistureEntityId!.trim(),
    };
  }

  Future<List<GrowSpaceStageTarget>> getStageTargets(String growSpaceId) =>
      _dao.getStageTargetsForGrowSpace(growSpaceId);

  /// Replaces the overrides. Only rows whose values changed get a new
  /// updatedAt; empty drafts delete their row.
  Future<void> replaceStageTargets({
    required String growSpaceId,
    required List<GrowSpaceStageTargetDraft> drafts,
  }) async {
    final existing = await _dao.getStageTargetsForGrowSpace(growSpaceId);
    final existingByStage = {for (final row in existing) row.stageKey: row};
    final kept = {
      for (final d in drafts)
        if (!d.isEmpty) d.stageKey,
    };
    for (final row in existing) {
      if (!kept.contains(row.stageKey)) {
        await _dao.deleteStageTarget(growSpaceId, row.stageKey);
      }
    }
    final now = DateTime.now();
    for (final draft in drafts) {
      if (draft.isEmpty) continue;
      final current = existingByStage[draft.stageKey];
      if (current != null && _same(current, draft)) continue;
      await _dao.upsertStageTarget(
        GrowSpaceStageTargetsCompanion.insert(
          growSpaceId: growSpaceId,
          stageKey: draft.stageKey,
          tempMinF: Value(draft.tempMinF),
          tempMaxF: Value(draft.tempMaxF),
          humidityMinPct: Value(draft.humidityMinPct),
          humidityMaxPct: Value(draft.humidityMaxPct),
          vpdMinKpa: Value(draft.vpdMinKpa),
          vpdMaxKpa: Value(draft.vpdMaxKpa),
          createdAt: Value(current?.createdAt ?? now),
          updatedAt: Value(now),
        ),
      );
    }
  }

  bool _same(GrowSpaceStageTarget row, GrowSpaceStageTargetDraft d) =>
      row.tempMinF == d.tempMinF &&
      row.tempMaxF == d.tempMaxF &&
      row.humidityMinPct == d.humidityMinPct &&
      row.humidityMaxPct == d.humidityMaxPct &&
      row.vpdMinKpa == d.vpdMinKpa &&
      row.vpdMaxKpa == d.vpdMaxKpa;

  /// Names must be unique (case-insensitive): two spaces with one name are
  /// indistinguishable in every picker.
  Future<void> _assertNameIsFree(String name, {String? exceptId}) async {
    final candidate = name.trim().toLowerCase();
    if (candidate.isEmpty) throw StateError('Give the grow space a name.');
    final spaces = await _dao.getAllGrowSpaces();
    final clash = spaces.any(
      (s) => s.id != exceptId && s.name.trim().toLowerCase() == candidate,
    );
    if (clash) {
      throw StateError('A grow space named "${name.trim()}" already exists.');
    }
  }

  bool _valid(String? value) => value != null && value.trim().isNotEmpty;

  String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
