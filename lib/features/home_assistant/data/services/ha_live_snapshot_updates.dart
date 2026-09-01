import '../../../../core/database/database.dart';
import '../models/ha_live_update_models.dart';
import 'ha_live_routing.dart';

/// Pure snapshot update: rebuilds readings for [touched] grow spaces.
/// Returns null when none of them produced a usable reading.
HALiveTelemetrySnapshot? applyLiveReadings(
  HALiveTelemetrySnapshot current, {
  required HALiveRouting routing,
  required Set<String> touched,
  required DateTime now,
  required bool markLive,
}) {
  final readings = Map<String, HALiveReading>.from(current.readingsByGrowSpace);
  final receivedAt = Map<String, DateTime>.from(current.receivedAtByGrowSpace);
  final failed = Map<String, bool>.from(current.lastFetchFailedByGrowSpace);
  var anyUsable = false;
  for (final id in touched) {
    final reading = routing.readingFor(id);
    if (!reading.hasUsableValues) {
      failed[id] = true;
      continue;
    }
    readings[id] = reading;
    receivedAt[id] = now;
    failed[id] = false;
    anyUsable = true;
  }
  if (!anyUsable) return null;
  return current.copyWith(
    status: markLive ? HALiveConnectionStatus.live : current.status,
    readingsByGrowSpace: readings,
    receivedAtByGrowSpace: receivedAt,
    lastFetchFailedByGrowSpace: failed,
    lastFetchFailed: false,
    clearFailureReason: markLive,
  );
}

/// Marks every routed grow space as failed while keeping the last readings.
HALiveTelemetrySnapshot markLiveDegraded(
  HALiveTelemetrySnapshot current, {
  required String reason,
  required String? baseUrl,
  required Set<String> growSpaceIds,
}) {
  return current.copyWith(
    status: HALiveConnectionStatus.degradedRest,
    activeBaseUrl: baseUrl ?? current.activeBaseUrl,
    failureReason: reason,
    lastFetchFailed: true,
    lastFetchFailedByGrowSpace: {
      ...current.lastFetchFailedByGrowSpace,
      for (final id in growSpaceIds) id: true,
    },
  );
}

/// Only these settings fields should trigger a reconnect. Metadata writes
/// such as lastSuccessfulConnection must not, or a connection loop forms.
String liveSettingsSignature(HomeAssistantSetting? s) => s == null
    ? '__none__'
    : [
        s.isEnabled,
        s.baseUrl,
        s.liveWarnThresholdMinutes,
        s.liveStaleThresholdMinutes,
      ].join('|');

HALiveTelemetrySnapshot markLiveConnecting(
  HALiveTelemetrySnapshot s,
  HomeAssistantSetting? settings,
) =>
    s.copyWith(
      status: HALiveConnectionStatus.connecting,
      clearFailureReason: true,
      liveWarnThresholdMinutes: settings?.liveWarnThresholdMinutes ?? 5,
      liveStaleThresholdMinutes: settings?.liveStaleThresholdMinutes ?? 15,
    );

HALiveTelemetrySnapshot markLiveOffline(
  HALiveTelemetrySnapshot s,
  String reason,
) =>
    s.copyWith(status: HALiveConnectionStatus.offline, failureReason: reason);

HALiveTelemetrySnapshot markLiveConnected(
  HALiveTelemetrySnapshot s,
  String? baseUrl,
) =>
    s.copyWith(
      status: HALiveConnectionStatus.live,
      activeBaseUrl: baseUrl,
      clearFailureReason: true,
    );
