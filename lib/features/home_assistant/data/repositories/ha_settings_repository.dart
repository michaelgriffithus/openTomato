import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../../../../core/security/secure_storage.dart';

class HASettingsRepository {
  final HaSettingsDao _dao;
  final HaAccessTokenStore _tokenStore;

  const HASettingsRepository({
    required HaSettingsDao dao,
    required HaAccessTokenStore tokenStore,
  })  : _dao = dao,
        _tokenStore = tokenStore;

  Stream<HomeAssistantSetting?> watchSettings() => _dao.watchSettings();

  Future<HomeAssistantSetting?> getSettings() => _dao.getSettings();

  Future<String?> getAccessToken() => _tokenStore.read();

  Future<bool> get isConfigured async {
    final settings = await _dao.getSettings();
    final token = await _tokenStore.read();
    return settings != null &&
        settings.isEnabled &&
        (settings.baseUrl?.trim().isNotEmpty ?? false) &&
        (token?.isNotEmpty ?? false);
  }

  /// Saves the connection. The token goes to secure storage, never to the
  /// database. An empty [accessToken] keeps the token already stored.
  Future<void> saveSettings({
    required String baseUrl,
    required String accessToken,
    required bool isEnabled,
    required int pollIntervalMinutes,
    required int liveWarnThresholdMinutes,
    required int liveStaleThresholdMinutes,
  }) async {
    final now = DateTime.now();
    final existing = await _dao.getSettings();
    final warn = liveWarnThresholdMinutes.clamp(1, 240);
    final stale = _normalizeStale(liveStaleThresholdMinutes, warn);
    final url = normalizeUrl(baseUrl);
    final interval = pollIntervalMinutes.clamp(10, 240);

    if (existing == null) {
      await _dao.insertSettings(
        HomeAssistantSettingsCompanion.insert(
          baseUrl: Value(url),
          isEnabled: Value(isEnabled),
          pollIntervalMinutes: Value(interval),
          liveWarnThresholdMinutes: Value(warn),
          liveStaleThresholdMinutes: Value(stale),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    } else {
      await _dao.writeSettings(
        existing.id,
        HomeAssistantSettingsCompanion(
          baseUrl: Value(url),
          isEnabled: Value(isEnabled),
          pollIntervalMinutes: Value(interval),
          liveWarnThresholdMinutes: Value(warn),
          liveStaleThresholdMinutes: Value(stale),
          updatedAt: Value(now),
        ),
      );
    }
    if (accessToken.trim().isNotEmpty) {
      await _tokenStore.write(accessToken.trim());
    }
  }

  /// Informational only. Nothing gates on this value.
  Future<void> updateLastSuccessfulConnection(DateTime timestamp) async {
    final existing = await _dao.getSettings();
    if (existing == null) return;
    await _dao.writeSettings(
      existing.id,
      HomeAssistantSettingsCompanion(
        lastSuccessfulConnection: Value(timestamp),
      ),
    );
  }

  Future<void> deleteSettings() async {
    final existing = await _dao.getSettings();
    await _tokenStore.delete();
    if (existing != null) await _dao.deleteSettings(existing.id);
  }

  static String? normalizeUrl(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static int _normalizeStale(int minutes, int warn) {
    final normalized = minutes.clamp(2, 1440);
    return normalized <= warn ? warn + 1 : normalized;
  }
}
