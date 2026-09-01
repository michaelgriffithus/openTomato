import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../../domain/exceptions/ha_exceptions.dart';
import 'ha_client.dart';
import 'ha_endpoint_resolver.dart';
import 'ha_reading_normalizer.dart';

class HaHistoryPoint {
  final DateTime timestamp;
  final double value;

  const HaHistoryPoint({required this.timestamp, required this.value});
}

/// Reads `/api/history/period` for one entity and returns canonical values.
class HaHistoryService {
  final HAEndpointResolver _endpoint;
  final HARestClient _restClient;
  final HAReadingNormalizer _normalizer;
  final http.Client Function()? _clientFactory;

  /// A multi-day recorder query is slower than a live-state fetch.
  static const Duration seriesTimeout = Duration(seconds: 20);

  const HaHistoryService({
    required HAEndpointResolver endpoint,
    required HARestClient restClient,
    HAReadingNormalizer normalizer = const HAReadingNormalizer(),
    http.Client Function()? clientFactory,
  })  : _endpoint = endpoint,
        _restClient = restClient,
        _normalizer = normalizer,
        _clientFactory = clientFactory;

  /// Timestamped history for one entity in canonical units. An empty list
  /// means the recorder has nothing for the window, which is normal.
  Future<List<HaHistoryPoint>> getEntityHistorySeries({
    required String entityId,
    required DateTime from,
    required DateTime to,
    required String field,
  }) async {
    final id = HARestClient.validatedEntityId(entityId);
    if (!from.isBefore(to)) {
      throw HAInvalidDataException('from must be before to');
    }
    if (to.difference(from) > const Duration(days: 30)) {
      throw HAInvalidDataException('history window must be 30 days or less');
    }
    final baseUrl = await _endpoint.resolveBaseUrl();
    final token = await _endpoint.resolveAccessToken();
    final uri = HARestClient.buildApiUri(
      baseUrl,
      ['api', 'history', 'period', from.toUtc().toIso8601String()],
    ).replace(
      queryParameters: {
        'filter_entity_id': id,
        'end_time': to.toUtc().toIso8601String(),
        'minimal_response': 'true',
        'no_attributes': 'true',
      },
    );

    final client = _clientFactory?.call() ?? IOClient(HttpClient());
    try {
      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(seriesTimeout);
      if (response.statusCode == 401) throw HAAuthenticationException();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HAApiException(
          'History request failed (HTTP ${response.statusCode}).',
          response.statusCode,
          'Unable to load Home Assistant history.',
        );
      }
      final decoded = json.decode(response.body);
      if (decoded is! List || decoded.isEmpty) return const [];
      final rows = decoded.first;
      if (rows is! List || rows.isEmpty) return const [];

      // History rows are bare numbers, so temperature and VPD need the
      // entity's unit to reach canonical °F / kPa.
      String? unit;
      if (field == HAReadingNormalizer.temperature ||
          field == HAReadingNormalizer.vpd) {
        try {
          unit = (await _restClient.fetchEntityState(baseUrl, token, id)).unit;
        } on Exception catch (error) {
          debugPrint('HA history unit lookup failed for $id: $error');
        }
      }

      final points = <HaHistoryPoint>[];
      for (final row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final rawTimestamp = row['last_changed'] ?? row['last_updated'];
        if (rawTimestamp is! String) continue;
        final timestamp = DateTime.tryParse(rawTimestamp)?.toLocal();
        if (timestamp == null ||
            timestamp.isBefore(from) ||
            timestamp.isAfter(to)) {
          continue;
        }
        final value = _normalize(field, row['state'], unit);
        if (value == null) continue;
        points.add(HaHistoryPoint(timestamp: timestamp, value: value));
      }
      points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return points;
    } on TimeoutException {
      throw HAConnectionException(
        'History request timed out after ${seriesTimeout.inSeconds}s.',
        'Home Assistant history request timed out.',
      );
    } on SocketException catch (error) {
      throw HARestClient.mapSocketException(error);
    } finally {
      client.close();
    }
  }

  double? _normalize(String field, dynamic rawValue, String? unit) {
    final raw =
        rawValue is num ? rawValue.toDouble() : double.tryParse('$rawValue');
    if (raw == null || !raw.isFinite) return null;
    return switch (field) {
      HAReadingNormalizer.temperature =>
        _normalizer.temperatureFFromRaw(raw, unit),
      HAReadingNormalizer.vpd => _normalizer.vpdKpaFromRaw(raw, unit),
      _ => raw,
    };
  }
}
