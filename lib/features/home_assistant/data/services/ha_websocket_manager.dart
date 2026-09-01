import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../domain/exceptions/ha_exceptions.dart';
import 'ha_websocket_client.dart';

class HAWebSocketManager {
  static const Duration _defaultMaxReconnectBackoff = Duration(seconds: 30);

  final HAWebSocketClient _webSocketClient;
  final Duration _maxReconnectBackoff;
  final StreamController<Map<String, dynamic>> _rawEventsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  StreamSubscription<Map<String, dynamic>>? _eventsSub;
  StreamSubscription<bool>? _connectionSub;
  Timer? _reconnectTimer;
  bool _active = false;
  bool _connecting = false;
  bool _disposed = false;
  Duration _nextReconnectDelay = const Duration(seconds: 1);
  String? _baseUrl;
  String? _accessToken;

  HAWebSocketManager({
    required HAWebSocketClient webSocketClient,
    Duration maxReconnectBackoff = _defaultMaxReconnectBackoff,
  })  : _webSocketClient = webSocketClient,
        _maxReconnectBackoff = maxReconnectBackoff;

  Stream<Map<String, dynamic>> get rawEvents => _rawEventsController.stream;
  Stream<bool> get connectionStateChanges => _connectionStateController.stream;

  bool isConnected() => _webSocketClient.isConnected();

  Future<void> connect({
    required String baseUrl,
    required String accessToken,
    required bool forceReconnect,
  }) async {
    if (_disposed) {
      return;
    }
    _active = true;
    _baseUrl = baseUrl;
    _accessToken = accessToken;
    await _ensureConnected(forceReconnect: forceReconnect);
  }

  Future<void> disconnect() async {
    _active = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _eventsSub?.cancel();
    _eventsSub = null;
    await _connectionSub?.cancel();
    _connectionSub = null;
    await _webSocketClient.disconnect();
    _emitConnectionState(false);
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    await _rawEventsController.close();
    await _connectionStateController.close();
  }

  Future<void> _ensureConnected({required bool forceReconnect}) async {
    final baseUrl = _baseUrl;
    final accessToken = _accessToken;
    if (_disposed ||
        !_active ||
        _connecting ||
        baseUrl == null ||
        accessToken == null) {
      return;
    }
    _reconnectTimer?.cancel();
    if (forceReconnect) {
      await _disconnectSocketOnly();
      if (_disposed || !_active) {
        return;
      }
    } else if (_webSocketClient.isConnected()) {
      return;
    }

    _connecting = true;
    try {
      await _webSocketClient.connect(baseUrl, accessToken);
      await _webSocketClient.subscribeToStateChanges();
      await _eventsSub?.cancel();
      await _connectionSub?.cancel();
      _eventsSub = _webSocketClient.events.listen(
        (event) {
          if (!_rawEventsController.isClosed) {
            _rawEventsController.add(event);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('HA websocket manager events error: $error');
          _emitConnectionState(false);
          if (_active) {
            _scheduleReconnect();
          }
        },
      );
      _connectionSub = _webSocketClient.connectionStateChanges.listen(
        (
          connected,
        ) {
          _emitConnectionState(connected);
          if (!connected && _active) {
            _scheduleReconnect();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('HA websocket manager connection error: $error');
          _emitConnectionState(false);
          if (_active) {
            _scheduleReconnect();
          }
        },
      );
      _nextReconnectDelay = const Duration(seconds: 1);
      _emitConnectionState(true);
    } on HAException {
      _emitConnectionState(false);
      _scheduleReconnect();
      rethrow;
    } catch (error) {
      _emitConnectionState(false);
      _scheduleReconnect();
      throw HAConnectionException(
        'Home Assistant WebSocket manager error: $error',
        'Home Assistant live connection failed. OpenTomato will retry.',
      );
    } finally {
      _connecting = false;
    }
  }

  Future<void> _disconnectSocketOnly() async {
    await _eventsSub?.cancel();
    _eventsSub = null;
    await _connectionSub?.cancel();
    _connectionSub = null;
    await _webSocketClient.disconnect();
    _emitConnectionState(false);
  }

  void _scheduleReconnect() {
    if (_disposed || !_active || _connecting || _reconnectTimer != null) {
      return;
    }
    final delay = _nextReconnectDelay;
    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      if (_disposed || !_active) {
        return;
      }
      try {
        await _ensureConnected(forceReconnect: true);
      } catch (error) {
        debugPrint('HA websocket manager reconnect failed: $error');
      }
    });
    final jitterSeconds = math.min(
      2,
      math.max(0, (_nextReconnectDelay.inSeconds / 2).floor()),
    );
    final nextSeconds = (_nextReconnectDelay.inSeconds * 2 + jitterSeconds)
        .clamp(1, _maxReconnectBackoff.inSeconds);
    _nextReconnectDelay = Duration(seconds: nextSeconds);
  }

  void _emitConnectionState(bool connected) {
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(connected);
    }
  }
}
