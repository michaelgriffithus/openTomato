import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key-value contract over the platform keychain, so tests can
/// substitute an in-memory store.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  final FlutterSecureStorage _storage;

  const FlutterSecureKeyValueStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Assistant provider API keys, keyed by the provider row id.
class AiApiKeyStore {
  static const String _prefix = 'ai_provider_api_key_';

  final SecureKeyValueStore _storage;

  const AiApiKeyStore(this._storage);

  Future<String?> read(int id) => _storage.read('$_prefix$id');

  Future<void> write(int id, String value) =>
      _storage.write('$_prefix$id', value);

  Future<void> delete(int id) => _storage.delete('$_prefix$id');
}

/// The Home Assistant long-lived token. Never stored in the database.
class HaAccessTokenStore {
  static const String _key = 'ha_access_token';

  final SecureKeyValueStore _storage;

  const HaAccessTokenStore(this._storage);

  Future<String?> read() => _storage.read(_key);

  Future<void> write(String value) => _storage.write(_key, value);

  Future<void> delete() => _storage.delete(_key);
}
