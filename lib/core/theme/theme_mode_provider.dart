import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/daos/app_settings_dao.dart';
import '../providers/database_provider.dart';

const _themeModeSettingKey = 'theme_mode';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(appSettingsDaoProvider))..load();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final AppSettingsDao _dao;

  ThemeModeNotifier(this._dao) : super(ThemeMode.system);

  Future<void> load() async {
    final value = await _dao.getSetting(_themeModeSettingKey);
    state = _fromValue(value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _dao.setSetting(_themeModeSettingKey, _toValue(mode));
  }

  ThemeMode _fromValue(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  String _toValue(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }
}
