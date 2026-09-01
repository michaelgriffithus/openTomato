import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/ai_exceptions.dart';
import '../models/ai_message.dart';
import 'ai_provider_client.dart';

/// Claude Messages API over raw HTTP. Thinking is left at the model default
/// (adaptive on current models); no sampling parameters are sent because
/// current models reject them.
class AnthropicClient implements AiProviderClient {
  static const String defaultBaseUrl = 'https://api.anthropic.com/v1';
  static const String apiVersion = '2023-06-01';
  static const String defaultModel = 'claude-opus-5';
  static const List<String> suggestedModels = [
    'claude-opus-5',
    'claude-sonnet-5',
    'claude-haiku-4-5',
  ];

  final http.Client Function() _clientFactory;

  AnthropicClient({http.Client Function()? clientFactory})
      : _clientFactory = clientFactory ?? http.Client.new;

  @override
  String get providerName => 'anthropic';

  Map<String, String> _headers(String apiKey) => {
        'x-api-key': apiKey,
        'anthropic-version': apiVersion,
        'Content-Type': 'application/json',
      };

  Map<String, dynamic> _body({
    required String model,
    required List<AiMessage> messages,
    required int maxTokens,
    required bool stream,
  }) {
    final system = messages
        .where((m) => m.role == 'system')
        .map((m) => m.content)
        .join('\n\n');
    return {
      'model': model,
      'max_tokens': maxTokens,
      if (system.isNotEmpty) 'system': system,
      'messages': [
        for (final m in messages)
          if (m.role != 'system') m.toJson(),
      ],
      if (stream) 'stream': true,
    };
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
      final request = http.Request(
        'POST',
        Uri.parse('${baseUrl ?? defaultBaseUrl}/messages'),
      )
        ..headers.addAll(_headers(apiKey))
        ..body = json.encode(
          _body(
            model: model,
            messages: messages,
            maxTokens: maxTokens,
            stream: true,
          ),
        );
      final response =
          await client.send(request).timeout(const Duration(seconds: 90));
      await _throwForStatus(response);

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!line.startsWith('data: ')) continue;
        final Map<String, dynamic> event;
        try {
          event = json.decode(line.substring(6)) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }
        switch (event['type']) {
          case 'content_block_delta':
            final delta = event['delta'];
            if (delta is Map && delta['type'] == 'text_delta') {
              final text = delta['text'];
              if (text is String && text.isNotEmpty) yield text;
            }
          case 'message_delta':
            final delta = event['delta'];
            if (delta is Map && delta['stop_reason'] == 'refusal') {
              throw const ModelDeclinedException();
            }
          case 'error':
            final error = event['error'];
            throw ApiErrorException(
              error is Map ? '${error['message']}' : 'Anthropic stream error',
            );
        }
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
            Uri.parse('${baseUrl ?? defaultBaseUrl}/messages'),
            headers: _headers(apiKey),
            body: json.encode(
              _body(
                model: model,
                messages: const [AiMessage.user('Reply with OK.')],
                maxTokens: 5,
                stream: false,
              ),
            ),
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

  Future<void> _throwForStatus(http.StreamedResponse response) async {
    if (response.statusCode < 400) return;
    if (response.statusCode == 401) {
      throw const InvalidApiKeyException('Anthropic');
    }
    if (response.statusCode == 429) throw const RateLimitException('Anthropic');
    final body = await response.stream.bytesToString();
    throw ApiErrorException(
      _messageFrom(response.statusCode, body),
      response.statusCode,
    );
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
      _ => 'Anthropic returned HTTP $status.',
    };
  }
}
