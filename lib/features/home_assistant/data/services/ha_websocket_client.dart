import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/exceptions/ha_exceptions.dart';

typedef HAWebSocketConnector = Future<WebSocket> Function(Uri uri);

/// Raw Home Assistant WebSocket: auth handshake, then `subscribe_events`.
class HAWebSocketClient {
  static const Duration _defaultConnectTimeout = Duration(seconds: 5);
  static const Duration _defaultAuthenticationTimeout = Duration(seconds: 10);

  final HAWebSocketConnector _connectSocket;
  final Duration _connectTimeout;
  final Duration _authenticationTimeout;
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  int _nextMessageId = 1;
  bool _connected = false;
  bool _disposed = false;
  int _sessionId = 0;

  HAWebSocketClient({
    HAWebSocketConnector? connectSocket,
    Duration connectTimeout = _defaultConnectTimeout,
    Duration authenticationTimeout = _defaultAuthenticationTimeout,
  })  : _connectSocket =
            connectSocket ?? ((uri) => WebSocket.connect(uri.toString())),
        _connectTimeout = connectTimeout,
        _authenticationTimeout = authenticationTimeout;

  Stream<Map<String, dynamic>> get events => _eventsController.stream;
  Stream<bool> get connectionStateChanges => _connectionController.stream;

  bool isConnected() => _connected;

  Future<void> connect(String baseUrl, String accessToken) async {
    if (_disposed) throw StateError('WebSocket client has been disposed.');
    await disconnect();
    final sessionId = ++_sessionId;
    final socket = await _openSocket(baseUrl);
    final authCompleter = Completer<void>();
    unawaited(
      socket.done.catchError((Object error, StackTrace stackTrace) {
        if (sessionId != _sessionId) return;
        if (!authCompleter.isCompleted) {
          authCompleter.completeError(mapSocketError(error), stackTrace);
        }
        _setConnected(false);
      }),
    );
    var authenticated = false;

    late final StreamSubscription<dynamic> subscription;
    subscription = socket.listen(
      (dynamic data) {
        if (_disposed || sessionId != _sessionId) return;
        final parsed = _decodeMessage(data);
        if (parsed == null) return;
        if (!authenticated) {
          switch (parsed['type']?.toString()) {
            case 'auth_required':
              socket.add(
                jsonEncode({'type': 'auth', 'access_token': accessToken}),
              );
            case 'auth_ok':
              authenticated = true;
              if (!authCompleter.isCompleted) authCompleter.complete();
            case 'auth_invalid':
              if (!authCompleter.isCompleted) {
                authCompleter.completeError(HAAuthenticationException());
              }
          }
          return;
        }
        if (!_eventsController.isClosed) _eventsController.add(parsed);
      },
      onDone: () {
        if (sessionId != _sessionId) return;
        if (!authCompleter.isCompleted) {
          authCompleter.completeError(
            HAClosedSocketException('WebSocket closed during authentication.'),
          );
        }
        _setConnected(false);
      },
      onError: (Object error) {
        if (sessionId != _sessionId) return;
        if (!authCompleter.isCompleted) {
          authCompleter.completeError(mapSocketError(error));
        }
        _setConnected(false);
      },
      cancelOnError: false,
    );

    try {
      await authCompleter.future.timeout(_authenticationTimeout);
      if (_disposed || sessionId != _sessionId) {
        throw HAClosedSocketException(
          'WebSocket connection was superseded before authentication completed.',
        );
      }
      _socket = socket;
      _subscription = subscription;
      _setConnected(true);
    } on TimeoutException {
      final error = HAWebSocketTimeoutException(
        'Timed out waiting for Home Assistant WebSocket authentication.',
      );
      debugPrint('HA websocket connect failed: ${error.message}');
      await _cleanupSocket(socket, subscription, sessionId);
      throw error;
    } on HAAuthenticationException {
      await _cleanupSocket(socket, subscription, sessionId);
      rethrow;
    } catch (error) {
      final mapped = mapSocketError(error);
      debugPrint('HA websocket connect failed: ${mapped.message}');
      await _cleanupSocket(socket, subscription, sessionId);
      throw mapped;
    }
  }

  Future<void> disconnect() async {
    final sessionId = ++_sessionId;
    _setConnected(false);
    final subscription = _subscription;
    _subscription = null;
    final socket = _socket;
    _socket = null;
    await _cleanupSocket(socket, subscription, sessionId);
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    await _eventsController.close();
    await _connectionController.close();
  }

  Future<int> subscribeToStateChanges() => subscribeToEvents('state_changed');

  Future<int> subscribeToEvents([String? eventType]) async {
    final socket = _socket;
    if (!_connected || socket == null) {
      throw StateError('WebSocket is not connected.');
    }
    final id = _nextMessageId++;
    final payload = <String, dynamic>{'id': id, 'type': 'subscribe_events'};
    if (eventType != null && eventType.isNotEmpty) {
      payload['event_type'] = eventType;
    }
    socket.add(jsonEncode(payload));
    return id;
  }

  Future<WebSocket> _openSocket(String baseUrl) async {
    try {
      return await _connectSocket(toWebSocketUri(baseUrl))
          .timeout(_connectTimeout);
    } on TimeoutException {
      throw HAWebSocketTimeoutException(
        'Timed out opening Home Assistant WebSocket.',
      );
    } on HandshakeException catch (error) {
      throw HATlsHandshakeException(
        'Home Assistant WebSocket TLS handshake failed: $error',
      );
    } on SocketException catch (error) {
      throw mapSocketError(error);
    }
  }

  static Uri toWebSocketUri(String baseUrl) {
    final uri = Uri.parse(baseUrl.trim());
    return uri.replace(
      scheme: uri.scheme == 'https' ? 'wss' : 'ws',
      pathSegments: [
        ...uri.pathSegments.where((s) => s.isNotEmpty),
        'api',
        'websocket',
      ],
      queryParameters: null,
      fragment: null,
    );
  }

  Map<String, dynamic>? _decodeMessage(dynamic data) {
    if (data is! String) return null;
    final decoded = json.decode(data);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  static HAConnectionException mapSocketError(Object error) {
    if (error is HAConnectionException) return error;
    if (error is TimeoutException) {
      return HAWebSocketTimeoutException(
        'Timed out while waiting for Home Assistant WebSocket activity.',
      );
    }
    if (error is HandshakeException) {
      return HATlsHandshakeException(
        'Home Assistant WebSocket TLS handshake failed: $error',
      );
    }
    if (error is SocketException &&
        error.message.toLowerCase().contains('closed socket')) {
      return HAClosedSocketException(
        'Home Assistant socket was closed while reading: $error',
      );
    }
    return HAConnectionException(
      'Home Assistant WebSocket error: $error',
      'Home Assistant live connection failed. OpenTomato will retry.',
    );
  }

  Future<void> _cleanupSocket(
    WebSocket? socket,
    StreamSubscription<dynamic>? subscription,
    int sessionId,
  ) async {
    try {
      await subscription?.cancel();
    } catch (error) {
      debugPrint('HA websocket subscription cleanup failed: $error');
    }
    try {
      await socket?.close();
    } catch (error) {
      debugPrint('HA websocket close failed: $error');
    } finally {
      if (sessionId == _sessionId) _setConnected(false);
    }
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    if (!_connectionController.isClosed) _connectionController.add(value);
  }
}
