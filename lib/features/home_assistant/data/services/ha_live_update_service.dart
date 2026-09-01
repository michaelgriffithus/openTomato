import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ha_entity_state.dart';
import '../models/ha_live_session_result.dart';
import '../models/ha_live_update_models.dart';
import '../repositories/grow_spaces_repository.dart';
import '../repositories/ha_settings_repository.dart';
import 'ha_entity_state_parser.dart';
import 'ha_environment_sync_service.dart';
import 'ha_live_flush_scheduler.dart';
import 'ha_live_routing.dart';
import 'ha_live_session_coordinator.dart';
import 'ha_live_snapshot_updates.dart';
import 'ha_websocket_manager.dart';

/// Holds the live telemetry snapshot: connects while the app is in the
/// foreground, applies WebSocket state changes, and persists readings with a
/// debounce so a chatty sensor does not write a row per second.
class HALiveUpdateService extends StateNotifier<HALiveTelemetrySnapshot> {
  static const Duration defaultFlushDebounce = Duration(seconds: 15);
  static const Duration defaultMinPersistInterval = Duration(minutes: 1);

  final HASettingsRepository _settings;
  final GrowSpacesRepository _growSpaces;
  final HAEntityStateParser _parser;
  final HaEnvironmentSyncService _sync;
  final HALiveSessionCoordinator _coordinator;
  final HALiveRouting _routing;
  final DateTime Function() _now;
  late final HALiveFlushScheduler _flush;

  StreamSubscription<dynamic>? _settingsSub;
  StreamSubscription<dynamic>? _spacesSub;
  StreamSubscription<Map<String, dynamic>>? _rawEventsSub;
  StreamSubscription<bool>? _connectionSub;
  bool _foregroundActive = false;
  bool _connecting = false;
  bool _disposed = false;
  String? _lastSignature;

  HALiveUpdateService({
    required HASettingsRepository settings,
    required GrowSpacesRepository growSpaces,
    required HAWebSocketManager webSocketManager,
    required HAEntityStateParser parser,
    required HaEnvironmentSyncService sync,
    required HALiveSessionCoordinator coordinator,
    HALiveRouting? routing,
    Duration flushDebounce = defaultFlushDebounce,
    Duration minPersistInterval = defaultMinPersistInterval,
    DateTime Function()? now,
  })  : _settings = settings,
        _growSpaces = growSpaces,
        _parser = parser,
        _sync = sync,
        _coordinator = coordinator,
        _routing = routing ?? HALiveRouting(),
        _now = now ?? DateTime.now,
        super(HALiveTelemetrySnapshot.initial()) {
    _flush = HALiveFlushScheduler(
      debounce: flushDebounce,
      minPersistInterval: minPersistInterval,
      persist: _persist,
    );
    _settingsSub = _settings.watchSettings().listen((settings) {
      final next = liveSettingsSignature(settings);
      final previous = _lastSignature;
      _lastSignature = next;
      if (previous != null && previous != next) _refreshIfForeground();
    });
    _spacesSub =
        _growSpaces.watchGrowSpaces().listen((_) => _refreshIfForeground());
    _rawEventsSub = webSocketManager.rawEvents.listen(
      handleSocketEvent,
      onError: (Object _, StackTrace __) => _streamDown(retry: true),
    );
    _connectionSub = webSocketManager.connectionStateChanges.listen(
      (connected) {
        if (!connected) _streamDown(retry: false);
      },
    );
  }

  void _refreshIfForeground() {
    if (_foregroundActive) unawaited(refresh());
  }

  void _streamDown({required bool retry}) {
    if (!_foregroundActive) return;
    _markDegraded('Home Assistant live stream disconnected.');
    if (retry) _scheduleRetry();
  }

  Future<void> setForegroundActive(bool active) async {
    if (_disposed) return;
    _foregroundActive = active;
    await (active
        ? _ensureConnected(forceReconnect: false)
        : _disconnect(markIdle: true));
  }

  Future<void> refresh() async {
    if (_disposed) return;
    await _ensureConnected(forceReconnect: true);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _foregroundActive = false;
    _flush.cancel();
    for (final sub in [
      _settingsSub,
      _spacesSub,
      _rawEventsSub,
      _connectionSub,
    ]) {
      unawaited(sub?.cancel());
    }
    _coordinator.dispose();
    unawaited(_coordinator.disconnect());
    super.dispose();
  }

  Future<void> _ensureConnected({required bool forceReconnect}) async {
    if (_disposed || !_foregroundActive || _connecting) return;
    _connecting = true;
    try {
      _coordinator.cancelRetry();
      if (forceReconnect) {
        await _disconnect(markIdle: false);
        if (_disposed || !_foregroundActive) return;
      } else if (_state()?.status == HALiveConnectionStatus.live) {
        return;
      }
      final settings = await _settings.getSettings();
      await _routing.rebuild(_growSpaces);
      _update((s) => markLiveConnecting(s, settings));
      final result = await _coordinator.bootstrap(
        entityIds: _routing.entityIds,
        forceReconnect: forceReconnect,
        hasUsableSeededStates: _routing.hasUsableStates,
      );
      if (_disposed || !mounted) return;
      await _applyBootstrapResult(result);
    } catch (error) {
      _markDegraded(error.toString());
      _scheduleRetry();
    } finally {
      _connecting = false;
    }
  }

  Future<void> _applyBootstrapResult(HALiveSessionResult result) async {
    if (result.isOffline) {
      final configured = await _settings.isConfigured;
      if (!configured || _routing.isEmpty) {
        _update((s) => markLiveOffline(s, result.reason));
      } else {
        _markDegraded(result.reason, baseUrl: result.baseUrl);
      }
      if (result.shouldRetry) _scheduleRetry();
      return;
    }
    if (!_applyStates(result.seededStates)) {
      _markDegraded(
        'Unable to load Home Assistant readings.',
        baseUrl: result.baseUrl,
      );
      _scheduleRetry();
      return;
    }
    if (result.isLive) {
      _update((s) => markLiveConnected(s, result.baseUrl));
    } else {
      _markDegraded(result.reason, baseUrl: result.baseUrl);
    }
  }

  Future<void> _disconnect({required bool markIdle}) async {
    _coordinator.cancelRetry();
    _flush.reset();
    await _coordinator.disconnect();
    if (!_disposed && markIdle) {
      _update(
        (s) => s.copyWith(
          status: HALiveConnectionStatus.idle,
          clearActiveBaseUrl: true,
          clearFailureReason: true,
        ),
      );
    }
  }

  @visibleForTesting
  void handleSocketEvent(Map<String, dynamic> event) {
    final parsed = _parser.parseStateChangedEvent(event);
    if (parsed == null) return;
    final touched = _routing.apply(parsed.entityId, parsed.nextState);
    if (touched.isEmpty) return;
    if (_applyTouched(touched, markLive: true)) _queueFlush(touched);
  }

  bool _applyStates(Map<String, HAEntityState> states) {
    final touched = <String>{};
    for (final entry in states.entries) {
      touched.addAll(_routing.apply(entry.key, entry.value));
    }
    if (touched.isEmpty) return false;
    final ok = _applyTouched(touched, markLive: false);
    if (ok) _queueFlush(touched);
    return ok;
  }

  bool _applyTouched(Set<String> touched, {required bool markLive}) {
    final current = _state();
    if (current == null) return false;
    final next = applyLiveReadings(
      current,
      routing: _routing,
      touched: touched,
      now: _now(),
      markLive: markLive,
    );
    if (next == null) return false;
    _update((_) => next);
    return true;
  }

  void _queueFlush(Set<String> growSpaceIds) {
    _flush.queue(growSpaceIds, now: _now());
  }

  Future<void> _persist(Set<String> growSpaceIds) async {
    if (_disposed || !mounted) return;
    final current = _state();
    if (current == null) return;
    final pending = {
      for (final id in growSpaceIds)
        if (current.readingsByGrowSpace[id] != null)
          id: current.readingsByGrowSpace[id]!,
    };
    if (pending.isEmpty) return;
    await _sync.syncReadings(
      timestamp: _now(),
      readingsByGrowSpace: pending,
      source: HaEnvironmentSyncService.sourceLive,
    );
  }

  void _markDegraded(String reason, {String? baseUrl}) {
    _update(
      (s) => markLiveDegraded(
        s,
        reason: reason,
        baseUrl: baseUrl,
        growSpaceIds: _routing.growSpaceIds,
      ),
    );
  }

  void _scheduleRetry() {
    _coordinator.scheduleRetry(
      isForegroundActive: _foregroundActive,
      isConnecting: _connecting,
      onRetry: () => _ensureConnected(forceReconnect: true),
    );
  }

  HALiveTelemetrySnapshot? _state() {
    if (_disposed || !mounted) return null;
    try {
      return state;
    } on StateError {
      return null;
    }
  }

  void _update(HALiveTelemetrySnapshot Function(HALiveTelemetrySnapshot) fn) {
    final current = _state();
    if (current == null) return;
    try {
      state = fn(current);
    } on StateError {
      // Async completion after dispose; ignore.
    }
  }
}
