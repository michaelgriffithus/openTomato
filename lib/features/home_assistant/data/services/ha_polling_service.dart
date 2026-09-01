import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/database/database.dart';
import '../../domain/exceptions/ha_exceptions.dart';
import '../models/ha_live_update_models.dart';
import '../repositories/ha_settings_repository.dart';
import 'ha_environment_sync_service.dart';
import 'ha_service.dart';

/// Foreground REST poll on a timer. The live WebSocket path is the primary
/// source; this covers sensors that rarely change. No background isolate:
/// the app catches up from recorder history on resume instead.
class HaPollingService {
  final HASettingsRepository _settings;
  final HAService _haService;
  final HaEnvironmentSyncService _sync;
  final Future<Map<String, HALiveReading>> Function()? _readingsLoader;

  Timer? _timer;
  StreamSubscription<HomeAssistantSetting?>? _settingsSub;
  bool _running = false;
  String? _lastSignature;
  int? _activeIntervalMinutes;

  HaPollingService({
    required HASettingsRepository settings,
    required HAService haService,
    required HaEnvironmentSyncService sync,
    Future<Map<String, HALiveReading>> Function()? readingsLoader,
  })  : _settings = settings,
        _haService = haService,
        _sync = sync,
        _readingsLoader = readingsLoader;

  void start() {
    _settingsSub ??= _settings.watchSettings().listen((settings) {
      final next = _signature(settings);
      final previous = _lastSignature;
      _lastSignature = next;
      if (previous == null || previous == next) return;
      unawaited(configureFromSettings(triggerImmediate: true));
    });
    unawaited(configureFromSettings());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _activeIntervalMinutes = null;
    await _settingsSub?.cancel();
    _settingsSub = null;
  }

  String _signature(HomeAssistantSetting? s) => s == null
      ? '__none__'
      : [s.isEnabled, s.pollIntervalMinutes, s.baseUrl?.trim()].join('|');

  /// Enabled + URL is enough. Never gate on lastSuccessfulConnection: a
  /// device living on the live WebSocket path never records one.
  Future<void> configureFromSettings({bool triggerImmediate = false}) async {
    final settings = await _settings.getSettings();
    _lastSignature = _signature(settings);
    final canRun = settings != null &&
        settings.isEnabled &&
        (settings.baseUrl?.trim().isNotEmpty ?? false);
    if (!canRun) {
      _timer?.cancel();
      _timer = null;
      _activeIntervalMinutes = null;
      return;
    }
    final interval = settings.pollIntervalMinutes.clamp(10, 240);
    if (_timer == null || _activeIntervalMinutes != interval) {
      _timer?.cancel();
      _timer = Timer.periodic(
        Duration(minutes: interval),
        (_) => unawaited(runNowIfEligible()),
      );
      _activeIntervalMinutes = interval;
      unawaited(runNowIfEligible());
    } else if (triggerImmediate) {
      unawaited(runNowIfEligible());
    }
  }

  Future<bool> runNowIfEligible() async {
    final settings = await _settings.getSettings();
    if (settings == null ||
        !settings.isEnabled ||
        (settings.baseUrl?.trim().isEmpty ?? true) ||
        _running) {
      return false;
    }
    _running = true;
    try {
      final token = await _settings.getAccessToken();
      if (token == null || token.isEmpty) return false;
      final readings =
          await (_readingsLoader?.call() ?? _haService.fetchAllReadings());
      if (readings.isEmpty) return false;
      await _sync.syncReadings(
        timestamp: DateTime.now(),
        readingsByGrowSpace: readings,
        source: HaEnvironmentSyncService.sourcePoll,
      );
      return true;
    } on HAException catch (error) {
      debugPrint('HA poll skipped: ${error.message}');
      return false;
    } on Exception catch (error) {
      debugPrint('HA poll failed: $error');
      return false;
    } finally {
      _running = false;
    }
  }

  Future<bool> runManualSync() => runNowIfEligible();
}
