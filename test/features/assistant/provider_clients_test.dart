import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:open_tomato/features/assistant/data/models/ai_message.dart';
import 'package:open_tomato/features/assistant/data/providers/anthropic_client.dart';
import 'package:open_tomato/features/assistant/data/providers/openai_client.dart';
import 'package:open_tomato/features/assistant/domain/ai_exceptions.dart';

http.StreamedResponse _sse(List<String> lines, {int status = 200}) {
  final body = lines.map((l) => '$l\n').join();
  return http.StreamedResponse(Stream.value(utf8.encode(body)), status);
}

void main() {
  group('Anthropic client', () {
    test('sends system separately, no sampling params, parses text deltas',
        () async {
      http.Request? captured;
      final client = AnthropicClient(
        clientFactory: () => MockClient.streaming((request, bodyStream) async {
          captured = request as http.Request;
          return _sse([
            'event: message_start',
            'data: {"type":"message_start"}',
            'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hel"}}',
            'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"lo"}}',
            'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"}}',
            'data: {"type":"message_stop"}',
          ]);
        }),
      );
      final chunks = await client.sendMessageStreaming(
        apiKey: 'k',
        model: 'claude-opus-5',
        messages: const [AiMessage.system('sys'), AiMessage.user('hi')],
      ).toList();
      expect(chunks.join(), 'Hello');
      final body = json.decode(captured!.body) as Map<String, dynamic>;
      expect(body['system'], 'sys');
      expect(body['messages'], [
        {'role': 'user', 'content': 'hi'},
      ]);
      expect(body.containsKey('temperature'), isFalse);
      expect(body.containsKey('thinking'), isFalse);
      expect(body['stream'], isTrue);
      expect(captured!.headers['anthropic-version'], '2023-06-01');
      expect(captured!.headers['x-api-key'], 'k');
    });

    test('maps 401, 429, refusal', () async {
      AnthropicClient withStatus(int status) => AnthropicClient(
            clientFactory: () => MockClient.streaming(
              (_, __) async =>
                  _sse(['{"error":{"message":"nope"}}'], status: status),
            ),
          );
      Future<List<String>> run(AnthropicClient c) => c.sendMessageStreaming(
            apiKey: 'k',
            model: 'm',
            messages: const [AiMessage.user('x')],
          ).toList();
      expect(
        () => run(withStatus(401)),
        throwsA(isA<InvalidApiKeyException>()),
      );
      expect(() => run(withStatus(429)), throwsA(isA<RateLimitException>()));
      expect(() => run(withStatus(500)), throwsA(isA<ApiErrorException>()));
      final refusal = AnthropicClient(
        clientFactory: () => MockClient.streaming(
          (_, __) async => _sse([
            'data: {"type":"message_delta","delta":{"stop_reason":"refusal"}}',
          ]),
        ),
      );
      expect(() => run(refusal), throwsA(isA<ModelDeclinedException>()));
    });

    test('validateApiKey returns null on 200 and the message otherwise',
        () async {
      final ok = AnthropicClient(
        clientFactory: () => MockClient((_) async => http.Response('{}', 200)),
      );
      expect(await ok.validateApiKey('k', 'm'), isNull);
      final bad = AnthropicClient(
        clientFactory: () => MockClient(
          (_) async =>
              http.Response('{"error":{"message":"model not found"}}', 404),
        ),
      );
      expect(await bad.validateApiKey('k', 'm'), 'model not found');
    });
  });

  group('OpenAI client', () {
    test('streams deltas until [DONE], honours base URL', () async {
      http.Request? captured;
      final client = OpenAiClient(
        clientFactory: () => MockClient.streaming((request, _) async {
          captured = request as http.Request;
          return _sse([
            'data: {"choices":[{"delta":{"content":"A"},"finish_reason":null}]}',
            'data: {"choices":[{"delta":{"content":"B"},"finish_reason":null}]}',
            'data: [DONE]',
            'data: {"choices":[{"delta":{"content":"ignored"}}]}',
          ]);
        }),
      );
      final chunks = await client
          .sendMessageStreaming(
            apiKey: 'k',
            model: 'gpt-5',
            messages: const [AiMessage.user('hi')],
            baseUrl: 'http://localhost:11434/v1/',
          )
          .toList();
      expect(chunks.join(), 'AB');
      expect(
        captured!.url.toString(),
        'http://localhost:11434/v1/chat/completions',
      );
      final body = json.decode(captured!.body) as Map<String, dynamic>;
      expect(body['max_completion_tokens'], 4096);
      expect(body.containsKey('temperature'), isFalse);
    });

    test('content_filter finish reason is a decline', () async {
      final client = OpenAiClient(
        clientFactory: () => MockClient.streaming(
          (_, __) async => _sse([
            'data: {"choices":[{"delta":{},"finish_reason":"content_filter"}]}',
          ]),
        ),
      );
      expect(
        () => client.sendMessageStreaming(
          apiKey: 'k',
          model: 'm',
          messages: const [AiMessage.user('x')],
        ).toList(),
        throwsA(isA<ModelDeclinedException>()),
      );
    });
  });
}
