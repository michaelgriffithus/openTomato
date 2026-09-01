import 'dart:async';
import 'dart:math' as math;

import '../../domain/exceptions/ha_exceptions.dart';
import '../models/ha_entity_state.dart';
import '../models/ha_live_session_result.dart';
import 'ha_client.dart';
import 'ha_endpoint_resolver.dart';
import 'ha_websocket_manager.dart';

/// Opens the live session: connect the WebSocket, then seed current values
/// over REST so the UI has numbers before the first state change arrives.
class HALiveSessionCoordinator {
  final HAEndpointResolver _endpoint;
  final HAWebSocketManager _webSocketManager;
  final HARestClient _restClient;
  final Duration _maxRetryBackoff;

  Timer? _retryTimer;
  Duration _nextRetryDelay = const Duration(seconds: 1);
  bool _disposed = false;

  HALiveSessionCoordinator({
    required HAEndpointResolver endpoint,
    required HAWebSocketManager webSocketManager,
    required HARestClient restClient,
    Duration maxRetryBackoff = const Duration(seconds: 30),
  })  : _endpoint = endpoint,
        _webSocketManager = webSocketManager,
        _restClient = restClient,
        _maxRetryBackoff = maxRetryBackoff;

  Future<HALiveSessionResult> bootstrap({
    required Iterable<String> entityIds,
    required bool forceReconnect,
    required bool Function(Map<String, HAEntityState> states)
        hasUsableSeededStates,
  }) async {
    cancelRetry();
    final ids = entityIds.toList(growable: false);
    final String baseUrl;
    final String token;
    try {
      baseUrl = await _endpoint.resolveBaseUrl();
      token = await _endpoint.resolveAccessToken();
    } on HAException catch (error) {
      return HALiveSessionResult.offline(
        reason: error.userMessage,
        shouldRetry: false,
      );
    }
    if (ids.isEmpty) {
      return const HALiveSessionResult.offline(
        reason: 'No sensors are mapped to a grow space yet.',
        shouldRetry: false,
      );
    }

    var liveStreamReady = false;
    try {
      await _webSocketManager.connect(
        baseUrl: baseUrl,
        accessToken: token,
        forceReconnect: forceReconnect,
      );
      liveStreamReady = true;
    } on HAException {
      liveStreamReady = false;
    }

    try {
      final states =
          await _restClient.fetchMultipleEntities(baseUrl, token, ids);
      if (states.isEmpty) {
        return HALiveSessionResult.offline(
          baseUrl: baseUrl,
          reason: 'Home Assistant returned no entity states.',
        );
      }
      if (!hasUsableSeededStates(states)) {
        return HALiveSessionResult.offline(
          baseUrl: baseUrl,
          reason: 'Home Assistant returned no usable readings.',
        );
      }
      _nextRetryDelay = const Duration(seconds: 1);
      if (liveStreamReady) {
        return HALiveSessionResult.live(baseUrl: baseUrl, seededStates: states);
      }
      return HALiveSessionResult.fallback(
        baseUrl: baseUrl,
        seededStates: states,
        reason: 'Live stream unavailable; showing polled values.',
      );
    } on HAException catch (error) {
      return HALiveSessionResult.offline(
        baseUrl: baseUrl,
        reason: _reasonFor(error),
      );
    } catch (_) {
      return HALiveSessionResult.offline(
        baseUrl: baseUrl,
        reason: 'Unable to load Home Assistant live data.',
      );
    }
  }

  Future<void> disconnect() async {
    cancelRetry();
    await _webSocketManager.disconnect();
  }

  void scheduleRetry({
    required bool isForegroundActive,
    required bool isConnecting,
    required Future<void> Function() onRetry,
  }) {
    if (_disposed ||
        !isForegroundActive ||
        isConnecting ||
        _retryTimer != null) {
      return;
    }
    final delay = _nextRetryDelay;
    _retryTimer = Timer(delay, () async {
      _retryTimer = null;
      if (_disposed) return;
      await onRetry();
    });
    final jitter =
        math.min(2, math.max(0, (_nextRetryDelay.inSeconds / 2).floor()));
    final nextSeconds = (_nextRetryDelay.inSeconds * 2 + jitter)
        .clamp(1, _maxRetryBackoff.inSeconds);
    _nextRetryDelay = Duration(seconds: nextSeconds);
  }

  void cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void dispose() {
    _disposed = true;
    cancelRetry();
  }

  String _reasonFor(HAException error) {
    if (error is HATlsHandshakeException) {
      return 'Home Assistant HTTPS handshake failed.';
    }
    if (error is HAWebSocketTimeoutException) {
      return 'Home Assistant live connection timed out.';
    }
    if (error is HAClosedSocketException) {
      return 'Home Assistant connection closed unexpectedly.';
    }
    return error.userMessage;
  }
}
