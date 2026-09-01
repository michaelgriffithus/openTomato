import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiApiKeyStore {
  static const String _prefix = 'ai_provider_api_key_';

  final FlutterSecureStorage _storage;

  const AiApiKeyStore(this._storage);

  Future<String?> read(int id) {
    return _storage.read(key: '$_prefix$id');
  }

  Future<void> write(int id, String value) {
    return _storage.write(key: '$_prefix$id', value: value);
  }

  Future<void> delete(int id) {
    return _storage.delete(key: '$_prefix$id');
  }
}

class HaAccessTokenStore {
  static const String _key = 'ha_access_token';

  final FlutterSecureStorage _storage;

  const HaAccessTokenStore(this._storage);

  Future<String?> read() {
    return _storage.read(key: _key);
  }

  Future<void> write(String value) {
    return _storage.write(key: _key, value: value);
  }

  Future<void> delete() {
    return _storage.delete(key: _key);
  }
}
