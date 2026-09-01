import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../../domain/exceptions/ha_exceptions.dart';
import '../models/ha_discovered_entity.dart';
import '../models/ha_entity_state.dart';

/// Thin REST client for the three Home Assistant endpoints the app needs:
/// `/api/`, `/api/states`, and `/api/states/<entity>`.
class HARestClient {
  static const Duration defaultTimeout = Duration(seconds: 10);

  final http.Client Function()? _clientFactory;

  const HARestClient({http.Client Function()? clientFactory})
      : _clientFactory = clientFactory;

  Future<bool> testConnection(
    String baseUrl,
    String accessToken, {
    Duration timeout = defaultTimeout,
  }) async {
    return _guard(() async {
      final response = await _get(
        buildApiRootUri(baseUrl),
        headers: buildHeaders(accessToken),
        timeout: timeout,
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body is Map<String, dynamic> && body['message'] != null) {
          return true;
        }
        throw HAInvalidDataException();
      }
      if (response.statusCode == 401) throw HAAuthenticationException();
      throw HAConnectionException(
        'Unexpected response: ${response.statusCode}',
      );
    });
  }

  Future<HAEntityState> fetchEntityState(
    String baseUrl,
    String accessToken,
    String entityId,
  ) async {
    final normalizedEntityId = validatedEntityId(entityId);
    return _guard(() async {
      final response = await _get(
        buildApiUri(baseUrl, ['api', 'states', normalizedEntityId]),
        headers: buildHeaders(accessToken),
        timeout: defaultTimeout,
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body is Map<String, dynamic>) return HAEntityState.fromJson(body);
        throw HAInvalidDataException();
      }
      if (response.statusCode == 401) throw HAAuthenticationException();
      if (response.statusCode == 404) {
        throw HAEntityNotFoundException(normalizedEntityId);
      }
      throw HAApiException(
        'API error while fetching entity $normalizedEntityId',
        response.statusCode,
      );
    });
  }

  /// Fetches many entities, skipping ones that fail. Throws only when nothing
  /// could be fetched at all.
  Future<Map<String, HAEntityState>> fetchMultipleEntities(
    String baseUrl,
    String accessToken,
    List<String> entityIds,
  ) async {
    final results = <String, HAEntityState>{};
    HAConnectionException? lastTransportError;
    await Future.wait(
      entityIds.map((entityId) async {
        try {
          results[entityId] =
              await fetchEntityState(baseUrl, accessToken, entityId);
        } on HAConnectionException catch (error) {
          lastTransportError = error;
          debugPrint('HA entity fetch skipped for $entityId: ${error.message}');
        } on HAException catch (error) {
          debugPrint('HA entity fetch skipped for $entityId: ${error.message}');
        } catch (error) {
          debugPrint('HA entity fetch skipped for $entityId: $error');
        }
      }),
    );
    if (results.isEmpty && entityIds.isNotEmpty) {
      throw lastTransportError ??
          HAConnectionException(
            'No entities could be fetched',
            'Unable to fetch any mapped Home Assistant entities.',
          );
    }
    return results;
  }

  Future<List<HADiscoveredEntity>> fetchAllEntities(
    String baseUrl,
    String accessToken,
  ) async {
    return _guard(() async {
      final response = await _get(
        buildApiUri(baseUrl, const ['api', 'states']),
        headers: buildHeaders(accessToken),
        timeout: defaultTimeout,
      );
      if (response.statusCode == 401) throw HAAuthenticationException();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HAApiException(
          'API error while fetching entity list',
          response.statusCode,
        );
      }
      final body = json.decode(response.body);
      if (body is! List) throw HAInvalidDataException();
      return body
          .whereType<Map<String, dynamic>>()
          .map((row) {
            final attrs = row['attributes'];
            final attributes =
                attrs is Map<String, dynamic> ? attrs : <String, dynamic>{};
            return HADiscoveredEntity(
              entityId: row['entity_id']?.toString() ?? '',
              state: row['state']?.toString() ?? '',
              friendlyName: attributes['friendly_name']?.toString(),
              deviceClass: attributes['device_class']?.toString(),
              unit: attributes['unit_of_measurement']?.toString(),
              attributes: attributes,
            );
          })
          .where((e) => e.entityId.isNotEmpty)
          .toList(growable: false);
    });
  }

  Map<String, String> buildHeaders(String accessToken) => {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

  static String normalizeBase(String baseUrl) {
    final trimmed = baseUrl.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static Uri buildApiUri(String baseUrl, List<String> pathSegments) {
    final baseUri = Uri.parse(normalizeBase(baseUrl));
    final scheme = baseUri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      throw HAInvalidDataException(
        'Invalid Home Assistant URL scheme.',
        'The Home Assistant URL must start with http:// or https://.',
      );
    }
    if (baseUri.host.trim().isEmpty) {
      throw HAInvalidDataException(
        'Invalid Home Assistant URL host.',
        'The Home Assistant URL needs a host name or address.',
      );
    }
    return baseUri.replace(
      pathSegments: [
        ...baseUri.pathSegments.where((s) => s.isNotEmpty),
        ...pathSegments,
      ],
    );
  }

  static Uri buildApiRootUri(String baseUrl) {
    final apiUri = buildApiUri(baseUrl, const ['api']);
    final path = apiUri.path.endsWith('/') ? apiUri.path : '${apiUri.path}/';
    return apiUri.replace(path: path);
  }

  static String validatedEntityId(String entityId) {
    final normalized = entityId.trim();
    if (!RegExp(r'^[A-Za-z0-9_]+\.[A-Za-z0-9_]+$').hasMatch(normalized)) {
      throw HAInvalidDataException(
        'Invalid Home Assistant entity ID: $entityId',
        'Invalid Home Assistant entity ID configured.',
      );
    }
    return normalized;
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on TimeoutException {
      throw HAConnectionException(
        'Connection timeout',
        'Connection timed out.',
      );
    } on HandshakeException catch (error) {
      throw HATlsHandshakeException(
        'Home Assistant TLS handshake failed: $error',
      );
    } on SocketException catch (error) {
      throw mapSocketException(error);
    } on http.ClientException catch (e) {
      throw HAConnectionException('Client error: ${e.message}');
    }
  }

  static HAConnectionException mapSocketException(SocketException error) {
    if (error.message.toLowerCase().contains('closed socket')) {
      return HAClosedSocketException(
        'Home Assistant socket was closed while reading: $error',
      );
    }
    return HAConnectionException(
      'Cannot reach Home Assistant: ${error.message}',
      'Cannot reach Home Assistant.',
    );
  }

  Future<http.Response> _get(
    Uri uri, {
    required Map<String, String> headers,
    required Duration timeout,
  }) async {
    final factory = _clientFactory;
    if (factory != null) {
      final client = factory();
      try {
        return await client.get(uri, headers: headers).timeout(timeout);
      } finally {
        client.close();
      }
    }
    final httpClient = HttpClient()
      ..connectionTimeout = timeout
      ..idleTimeout = Duration.zero;
    final ioClient = IOClient(httpClient);
    try {
      return await ioClient.get(uri, headers: headers).timeout(timeout);
    } finally {
      ioClient.close();
      httpClient.close(force: true);
    }
  }
}

class HAClient extends HARestClient {
  const HAClient({super.clientFactory});
}
