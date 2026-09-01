import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/app_settings.dart';

part 'app_settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class AppSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$AppSettingsDaoMixin {
  AppSettingsDao(super.db);

  Future<String?> getSetting(String key) async {
    final setting = await (select(appSettings)
          ..where((tbl) => tbl.key.equals(key)))
        .getSingleOrNull();
    return setting?.value;
  }

  Stream<String?> watchSetting(String key) {
    return (select(appSettings)..where((tbl) => tbl.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insert(
      AppSettingsCompanion.insert(
        key: key,
        value: value,
        updatedAt: Value(DateTime.now()),
      ),
      onConflict: DoUpdate(
        (old) => AppSettingsCompanion(
          value: Value(value),
          updatedAt: Value(DateTime.now()),
        ),
        target: [appSettings.key],
      ),
    );
  }

  Future<bool> getBool(String key) async => await getSetting(key) == 'true';

  Future<void> setBool(String key, bool value) =>
      setSetting(key, value ? 'true' : 'false');

  Future<List<AppSetting>> getAllSettings() {
    return select(appSettings).get();
  }

  Future<int> deleteSetting(String key) {
    return (delete(appSettings)..where((tbl) => tbl.key.equals(key))).go();
  }
}
