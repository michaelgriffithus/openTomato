import '../../domain/exceptions/ha_exceptions.dart';
import '../repositories/ha_settings_repository.dart';

/// The one place that answers "which URL do I talk to?". One user-entered
/// base URL; no candidate ranking, no network-locality guessing.
class HAEndpointResolver {
  final HASettingsRepository _settings;

  const HAEndpointResolver(this._settings);

  Future<String> resolveBaseUrl() async {
    final settings = await _settings.getSettings();
    final url = settings?.baseUrl?.trim();
    if (settings == null || !settings.isEnabled || url == null || url.isEmpty) {
      throw HAConnectionException(
        'Home Assistant is not configured.',
        'Home Assistant is not connected. Add the URL and token in '
            'Settings → Home Assistant.',
      );
    }
    return url;
  }

  Future<String> resolveAccessToken() async {
    final token = await _settings.getAccessToken();
    if (token == null || token.isEmpty) {
      throw HAAuthenticationException(
        'No access token configured',
        'Home Assistant has no saved access token. Enter the long-lived '
            'token in Settings → Home Assistant and save.',
      );
    }
    return token;
  }
}
