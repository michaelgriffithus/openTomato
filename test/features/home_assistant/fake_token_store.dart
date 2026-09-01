import 'package:open_tomato/core/security/secure_storage.dart';

/// In-memory stand-in for the platform keychain.
class FakeSecureStorage implements SecureKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
