import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/ai_exceptions.dart';
import '../models/ai_message.dart';
import 'ai_provider_client.dart';

/// OpenAI chat completions over raw HTTP. [baseUrl] may point at any
/// OpenAI-compatible server.
class OpenAiClient implements AiProviderClient {
  static const String defaultBaseUrl = 'https://api.openai.com/v1';
  static const String defaultModel = 'gpt-5';
  static const List<String> suggestedModels = [
    'gpt-5',
    'gpt-5-mini',
    'gpt-4.1',
  ];

  final http.Client Function() _clientFactory;

  OpenAiClient({http.Client Function()? clientFactory})
      : _clientFactory = clientFactory ?? http.Client.new;

  @override
  String get providerName => 'openai';

  Map<String, String> _headers(String apiKey) => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  Uri _uri(String? baseUrl) {
    final base = (baseUrl ?? defaultBaseUrl).trim();
    final normalized =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return Uri.parse('$normalized/chat/completions');
  }

  @override
  Stream<String> sendMessageStreaming({
    required String apiKey,
    required String model,
    required List<AiMessage> messages,
    int maxTokens = 4096,
    String? baseUrl,
  }) async* {
    final client = _clientFactory();
    try {
      final request = http.Request('POST', _uri(baseUrl))
        ..headers.addAll(_headers(apiKey))
        ..body = json.encode({
          'model': model,
          'messages': [for (final m in messages) m.toJson()],
          'max_completion_tokens': maxTokens,
          'stream': true,
        });
      final response =
          await client.send(request).timeout(const Duration(seconds: 90));
      if (response.statusCode == 401) {
        throw const InvalidApiKeyException('OpenAI');
      }
      if (response.statusCode == 429) throw const RateLimitException('OpenAI');
      if (response.statusCode >= 400) {
        final body = await response.stream.bytesToString();
        throw ApiErrorException(
          _messageFrom(response.statusCode, body),
          response.statusCode,
        );
      }
      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data == '[DONE]') break;
        final Map<String, dynamic> decoded;
        try {
          decoded = json.decode(data) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }
        final error = decoded['error'];
        if (error is Map) {
          throw ApiErrorException(
            '${error['message'] ?? 'OpenAI stream error'}',
          );
        }
        final choices = decoded['choices'];
        if (choices is! List || choices.isEmpty) continue;
        final first = choices.first;
        if (first is! Map) continue;
        if (first['finish_reason'] == 'content_filter') {
          throw const ModelDeclinedException();
        }
        final delta = first['delta'];
        final content = delta is Map ? delta['content'] : null;
        if (content is String && content.isNotEmpty) yield content;
      }
    } on TimeoutException {
      throw const AiNetworkException(
        'Request timed out',
        'The request timed out.',
      );
    } on http.ClientException catch (e) {
      throw AiNetworkException('Network error: ${e.message}');
    } finally {
      client.close();
    }
  }

  @override
  Future<String?> validateApiKey(
    String apiKey,
    String model, {
    String? baseUrl,
  }) async {
    final client = _clientFactory();
    try {
      final response = await client
          .post(
            _uri(baseUrl),
            headers: _headers(apiKey),
            body: json.encode({
              'model': model,
              'messages': [const AiMessage.user('Reply with OK.').toJson()],
              'max_completion_tokens': 5,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) return null;
      return _messageFrom(response.statusCode, response.body);
    } on TimeoutException {
      return 'The request timed out.';
    } on http.ClientException catch (e) {
      return 'Network error: ${e.message}';
    } finally {
      client.close();
    }
  }

  String _messageFrom(int status, String body) {
    try {
      final decoded = json.decode(body);
      final error = decoded is Map ? decoded['error'] : null;
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
    } catch (_) {
      // fall through
    }
    return switch (status) {
      401 => 'The API key was rejected.',
      404 => 'That model name was not found.',
      429 => 'Rate limit reached.',
      _ => 'The provider returned HTTP $status.',
    };
  }
}
