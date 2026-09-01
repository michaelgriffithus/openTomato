import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/home_assistant_settings.dart';

part 'ha_settings_dao.g.dart';

@DriftAccessor(tables: [HomeAssistantSettings])
class HaSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$HaSettingsDaoMixin {
  HaSettingsDao(super.db);

  Future<HomeAssistantSetting?> getSettings() {
    return (select(homeAssistantSettings)
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<HomeAssistantSetting?> watchSettings() {
    return (select(homeAssistantSettings)
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<int> insertSettings(HomeAssistantSettingsCompanion companion) {
    return into(homeAssistantSettings).insert(companion);
  }

  Future<void> updateSettings(HomeAssistantSetting settings) async {
    await update(homeAssistantSettings).replace(settings);
  }

  /// Partial write so metadata updates never clobber user-entered fields.
  Future<int> writeSettings(int id, HomeAssistantSettingsCompanion companion) {
    return (update(homeAssistantSettings)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> deleteSettings(int id) async {
    await (delete(homeAssistantSettings)..where((tbl) => tbl.id.equals(id)))
        .go();
  }
}
