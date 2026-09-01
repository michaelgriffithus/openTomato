import '../../../core/database/daos/app_settings_dao.dart';

/// Per-provider consent that the grower has seen what leaves the device.
class CloudProviderConsent {
  const CloudProviderConsent._();

  static const supportedProviders = {'anthropic', 'openai'};

  static String providerLabel(String provider) => switch (provider) {
        'anthropic' => 'Anthropic',
        'openai' => 'OpenAI',
        _ => provider,
      };

  static String settingKey(String provider) =>
      'assistant.consent.$provider.accepted';

  static const disclaimerKey = 'assistant.disclaimer.accepted';

  static Future<bool> isAccepted(AppSettingsDao settings, String provider) =>
      settings.getBool(settingKey(provider));

  static Future<void> accept(AppSettingsDao settings, String provider) =>
      settings.setBool(settingKey(provider), true);
}
