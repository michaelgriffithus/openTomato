import 'package:drift/drift.dart';

import '../../../core/database/database.dart';
import '../../../core/security/secure_storage.dart';

/// Provider rows live in the database; keys live in secure storage keyed by
/// the row id.
class AiSettingsRepository {
  final AiSettingsDao _dao;
  final AiApiKeyStore _keys;

  const AiSettingsRepository(this._dao, this._keys);

  Stream<List<AiSetting>> watchAll() => _dao.watchAll();

  Future<List<AiSetting>> getAll() => _dao.getAll();

  Stream<AiSetting?> watchActive() => _dao.watchActive();

  Future<AiSetting?> getActive() => _dao.getActive();

  Future<AiSetting?> getByProvider(String provider) =>
      _dao.getByProvider(provider);

  Future<String?> getApiKey(int id) => _keys.read(id);

  Future<bool> hasApiKey(int id) async =>
      (await _keys.read(id))?.isNotEmpty ?? false;

  /// Creates or updates the row for [provider]. An empty [apiKey] keeps the
  /// stored one.
  Future<int> save({
    required String provider,
    required String modelName,
    required String apiKey,
    String? baseUrl,
    String? systemPromptOverride,
    int maxOutputTokens = 4096,
    bool makeActive = false,
  }) async {
    final now = DateTime.now();
    final existing = await _dao.getByProvider(provider);
    final cleanBase = baseUrl?.trim().isEmpty ?? true ? null : baseUrl!.trim();
    final cleanPrompt = systemPromptOverride?.trim().isEmpty ?? true
        ? null
        : systemPromptOverride!.trim();
    int id;
    if (existing == null) {
      id = await _dao.insertSetting(
        AiSettingsCompanion.insert(
          provider: provider,
          modelName: modelName.trim(),
          baseUrl: Value(cleanBase),
          maxOutputTokens: Value(maxOutputTokens),
          systemPromptOverride: Value(cleanPrompt),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    } else {
      id = existing.id;
      await _dao.writeSetting(
        id,
        AiSettingsCompanion(
          modelName: Value(modelName.trim()),
          baseUrl: Value(cleanBase),
          maxOutputTokens: Value(maxOutputTokens),
          systemPromptOverride: Value(cleanPrompt),
          updatedAt: Value(now),
        ),
      );
    }
    if (apiKey.trim().isNotEmpty) await _keys.write(id, apiKey.trim());
    if (makeActive) await _dao.setActive(id);
    return id;
  }

  Future<void> setActive(int id) => _dao.setActive(id);

  Future<void> clearActive() => _dao.clearActive();

  Future<void> delete(int id) async {
    await _dao.deleteSetting(id);
    await _keys.delete(id);
  }
}
