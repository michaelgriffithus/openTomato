import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/ai_settings.dart';

part 'ai_settings_dao.g.dart';

@DriftAccessor(tables: [AiSettings])
class AiSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$AiSettingsDaoMixin {
  AiSettingsDao(super.db);

  Stream<List<AiSetting>> watchAll() {
    return (select(aiSettings)..orderBy([(t) => OrderingTerm.asc(t.provider)]))
        .watch();
  }

  Future<List<AiSetting>> getAll() {
    return (select(aiSettings)..orderBy([(t) => OrderingTerm.asc(t.provider)]))
        .get();
  }

  Future<AiSetting?> getActive() {
    return (select(aiSettings)
          ..where((t) => t.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<AiSetting?> watchActive() {
    return (select(aiSettings)
          ..where((t) => t.isActive.equals(true))
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<AiSetting?> getById(int id) {
    return (select(aiSettings)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<AiSetting?> getByProvider(String provider) {
    return (select(aiSettings)..where((t) => t.provider.equals(provider)))
        .getSingleOrNull();
  }

  Future<int> insertSetting(AiSettingsCompanion companion) {
    return into(aiSettings).insert(companion);
  }

  Future<int> writeSetting(int id, AiSettingsCompanion companion) {
    return (update(aiSettings)..where((t) => t.id.equals(id))).write(companion);
  }

  /// Makes one provider active and every other one inactive.
  Future<void> setActive(int id) async {
    await transaction(() async {
      final now = DateTime.now();
      await (update(aiSettings)..where((t) => t.id.equals(id).not())).write(
        AiSettingsCompanion(
          isActive: const Value(false),
          updatedAt: Value(now),
        ),
      );
      await (update(aiSettings)..where((t) => t.id.equals(id))).write(
        AiSettingsCompanion(isActive: const Value(true), updatedAt: Value(now)),
      );
    });
  }

  Future<void> clearActive() async {
    await update(aiSettings).write(
      AiSettingsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteSetting(int id) {
    return (delete(aiSettings)..where((t) => t.id.equals(id))).go();
  }
}
