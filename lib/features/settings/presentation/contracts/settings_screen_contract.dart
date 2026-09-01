import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/contracts/app_identity_contract.dart';
import '../../../../core/providers/app_identity_provider.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../assistant/presentation/providers/assistant_providers.dart';
import '../../../home_assistant/presentation/providers/ha_providers.dart';
import '../../../plants/presentation/providers/plants_providers.dart';

enum AppearanceChoice { system, light, dark }

class SettingsScreenContract {
  const SettingsScreenContract({
    required this.appearance,
    required this.appearanceLabel,
    required this.plantsLabel,
    required this.homeAssistantLabel,
    required this.assistantLabel,
    required this.identity,
  });

  final AppearanceChoice appearance;
  final String appearanceLabel;
  final String plantsLabel;
  final String homeAssistantLabel;
  final String assistantLabel;
  final AppIdentityContract identity;
}

final settingsScreenContractProvider = Provider<SettingsScreenContract>((ref) {
  final theme = ref.watch(themeModeProvider);
  final plants = ref.watch(growActivePlantsProvider).valueOrNull ?? const [];
  final haConfigured = ref.watch(haIsConfiguredProvider).valueOrNull ?? false;
  final activeProvider = ref.watch(activeAiSettingProvider).valueOrNull;
  final appearance = switch (theme) {
    ThemeMode.system => AppearanceChoice.system,
    ThemeMode.light => AppearanceChoice.light,
    ThemeMode.dark => AppearanceChoice.dark,
  };
  return SettingsScreenContract(
    appearance: appearance,
    appearanceLabel: appearanceLabel(appearance),
    plantsLabel:
        '${plants.length} growing ${plants.length == 1 ? 'plant' : 'plants'}',
    homeAssistantLabel: haConfigured ? 'Connected' : 'Not connected',
    assistantLabel: activeProvider == null
        ? 'Add your own API key'
        : '${activeProvider.provider} · ${activeProvider.modelName}',
    identity: ref.watch(appIdentityContractProvider),
  );
});

String appearanceLabel(AppearanceChoice choice) => switch (choice) {
      AppearanceChoice.system => 'System',
      AppearanceChoice.light => 'Light',
      AppearanceChoice.dark => 'Dark',
    };
