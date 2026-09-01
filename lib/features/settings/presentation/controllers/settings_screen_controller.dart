import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../contracts/settings_screen_contract.dart';

final settingsScreenControllerProvider =
    Provider<SettingsScreenController>(SettingsScreenController.new);

class SettingsScreenController {
  const SettingsScreenController(this._ref);

  final Ref _ref;

  Future<void> setAppearance(AppearanceChoice choice) {
    final mode = switch (choice) {
      AppearanceChoice.system => ThemeMode.system,
      AppearanceChoice.light => ThemeMode.light,
      AppearanceChoice.dark => ThemeMode.dark,
    };
    return _ref.read(themeModeProvider.notifier).setThemeMode(mode);
  }
}
