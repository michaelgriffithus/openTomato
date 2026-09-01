import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:open_tomato/features/home_assistant/data/services/ha_client.dart';
import 'package:open_tomato/features/home_assistant/data/services/ha_websocket_client.dart';
import 'package:open_tomato/features/home_assistant/domain/exceptions/ha_exceptions.dart';

void main() {
  test('URL building keeps a base path and normalises trailing slashes', () {
    expect(
      HARestClient.buildApiUri('http://ha.local:8123/', ['api', 'states'])
          .toString(),
      'http://ha.local:8123/api/states',
    );
    expect(
      HARestClient.buildApiUri('https://home.example/ha', ['api']).toString(),
      'https://home.example/ha/api',
    );
    expect(HARestClient.buildApiRootUri('http://ha.local').path, '/api/');
    expect(
      () => HARestClient.buildApiUri('ha.local', ['api']),
      throwsA(isA<HAInvalidDataException>()),
    );
    expect(
      () => HARestClient.validatedEntityId('sensor.temp; drop'),
      throwsA(isA<HAInvalidDataException>()),
    );
    expect(HARestClient.validatedEntityId(' sensor.temp '), 'sensor.temp');
  });

  test('WebSocket URI maps http→ws and https→wss under /api/websocket', () {
    expect(
      HAWebSocketClient.toWebSocketUri('http://ha.local:8123').toString(),
      'ws://ha.local:8123/api/websocket',
    );
    expect(
      HAWebSocketClient.toWebSocketUri('https://home.example/ha/').toString(),
      'wss://home.example/ha/api/websocket',
    );
  });

  group('REST client', () {
    HAClient client(http.Response Function(http.Request) handler) => HAClient(
          clientFactory: () => MockClient((request) async => handler(request)),
        );

    test('testConnection succeeds on the API root message', () async {
      final c = client((r) {
        expect(r.url.path, '/api/');
        expect(r.headers['Authorization'], 'Bearer tok');
        return http.Response(jsonEncode({'message': 'API running.'}), 200);
      });
      expect(await c.testConnection('http://ha.local', 'tok'), isTrue);
    });

    test('401 maps to authentication, 404 to entity not found', () async {
      final unauthorized = client((_) => http.Response('', 401));
      expect(
        () => unauthorized.testConnection('http://ha.local', 'bad'),
        throwsA(isA<HAAuthenticationException>()),
      );
      final missing = client((_) => http.Response('', 404));
      expect(
        () => missing.fetchEntityState('http://ha.local', 'tok', 'sensor.nope'),
        throwsA(isA<HAEntityNotFoundException>()),
      );
    });

    test(
        'fetchMultipleEntities keeps partial results and throws only when all fail',
        () async {
      final partial = client((r) {
        if (r.url.path.endsWith('sensor.a')) {
          return http.Response(
            jsonEncode({
              'entity_id': 'sensor.a',
              'state': '70',
              'attributes': {},
              'last_changed': '2026-09-01T00:00:00Z',
            }),
            200,
          );
        }
        return http.Response('', 404);
      });
      final states = await partial.fetchMultipleEntities(
        'http://ha.local',
        'tok',
        ['sensor.a', 'sensor.b'],
      );
      expect(states.keys, ['sensor.a']);
      final none = client((_) => http.Response('', 500));
      expect(
        () =>
            none.fetchMultipleEntities('http://ha.local', 'tok', ['sensor.a']),
        throwsA(isA<HAConnectionException>()),
      );
    });

    test('fetchAllEntities parses device_class and unit', () async {
      final c = client(
        (_) => http.Response(
          jsonEncode([
            {
              'entity_id': 'sensor.t',
              'state': '72',
              'attributes': {
                'friendly_name': 'Tent temp',
                'device_class': 'temperature',
                'unit_of_measurement': '°F',
              },
            },
            {'entity_id': '', 'state': 'x'},
          ]),
          200,
        ),
      );
      final entities = await c.fetchAllEntities('http://ha.local', 'tok');
      expect(entities.single.displayLabel, 'Tent temp (°F)');
      expect(entities.single.deviceClass, 'temperature');
    });
  });
}
