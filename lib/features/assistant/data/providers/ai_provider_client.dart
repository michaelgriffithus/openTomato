import '../models/ai_message.dart';

/// A streaming chat client for one provider. Implementations talk raw HTTP
/// with the grower's own key; nothing is proxied.
abstract class AiProviderClient {
  String get providerName;

  /// Streams text chunks. Throws an [AiException] subclass on failure.
  Stream<String> sendMessageStreaming({
    required String apiKey,
    required String model,
    required List<AiMessage> messages,
    int maxTokens = 4096,
    String? baseUrl,
  });

  /// A tiny request that proves the key and model work. Returns null on
  /// success, otherwise a human-readable reason.
  Future<String?> validateApiKey(
    String apiKey,
    String model, {
    String? baseUrl,
  });
}
