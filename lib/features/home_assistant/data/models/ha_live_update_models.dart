enum HALiveConnectionStatus { idle, connecting, live, degradedRest, offline }

enum HALiveFreshnessStatus { healthy, warning, stale, offline }

class HALiveFreshness {
  final HALiveFreshnessStatus status;
  final DateTime? lastUpdatedAt;
  final Duration? age;
  final bool hasUsableValues;
  final bool lastAttemptFailed;

  const HALiveFreshness({
    required this.status,
    required this.lastUpdatedAt,
    required this.age,
    required this.hasUsableValues,
    required this.lastAttemptFailed,
  });

  bool get isHealthy => status == HALiveFreshnessStatus.healthy;
  bool get isDelayed => status == HALiveFreshnessStatus.warning;
  bool get isStale => status == HALiveFreshnessStatus.stale;
  bool get isOffline => status == HALiveFreshnessStatus.offline;
}

/// One grow space's latest live values in canonical units.
class HALiveReading {
  final double? tempF;
  final double? humidityPct;
  final double? vpdKpa;
  final double? soilMoisturePct;

  const HALiveReading({
    required this.tempF,
    required this.humidityPct,
    required this.vpdKpa,
    required this.soilMoisturePct,
  });

  static const empty = HALiveReading(
    tempF: null,
    humidityPct: null,
    vpdKpa: null,
    soilMoisturePct: null,
  );

  bool get hasAirValues =>
      tempF != null || humidityPct != null || vpdKpa != null;
  bool get hasUsableValues => hasAirValues || soilMoisturePct != null;
}

class HALiveTelemetrySnapshot {
  final HALiveConnectionStatus status;
  final Map<String, HALiveReading> readingsByGrowSpace;

  /// When the app RECEIVED the newest value for each grow space. Home
  /// Assistant's `last_updated` only advances when a value changes, so a
  /// steady sensor would otherwise age into false staleness.
  final Map<String, DateTime> receivedAtByGrowSpace;
  final Map<String, bool> lastFetchFailedByGrowSpace;
  final String? activeBaseUrl;
  final String? failureReason;
  final bool lastFetchFailed;
  final int liveWarnThresholdMinutes;
  final int liveStaleThresholdMinutes;

  const HALiveTelemetrySnapshot({
    required this.status,
    required this.readingsByGrowSpace,
    required this.receivedAtByGrowSpace,
    required this.lastFetchFailedByGrowSpace,
    required this.activeBaseUrl,
    required this.failureReason,
    required this.lastFetchFailed,
    required this.liveWarnThresholdMinutes,
    required this.liveStaleThresholdMinutes,
  });

  factory HALiveTelemetrySnapshot.initial() => const HALiveTelemetrySnapshot(
        status: HALiveConnectionStatus.idle,
        readingsByGrowSpace: {},
        receivedAtByGrowSpace: {},
        lastFetchFailedByGrowSpace: {},
        activeBaseUrl: null,
        failureReason: null,
        lastFetchFailed: false,
        liveWarnThresholdMinutes: 5,
        liveStaleThresholdMinutes: 15,
      );

  HALiveTelemetrySnapshot copyWith({
    HALiveConnectionStatus? status,
    Map<String, HALiveReading>? readingsByGrowSpace,
    Map<String, DateTime>? receivedAtByGrowSpace,
    Map<String, bool>? lastFetchFailedByGrowSpace,
    String? activeBaseUrl,
    bool clearActiveBaseUrl = false,
    String? failureReason,
    bool clearFailureReason = false,
    bool? lastFetchFailed,
    int? liveWarnThresholdMinutes,
    int? liveStaleThresholdMinutes,
  }) {
    return HALiveTelemetrySnapshot(
      status: status ?? this.status,
      readingsByGrowSpace: readingsByGrowSpace ?? this.readingsByGrowSpace,
      receivedAtByGrowSpace:
          receivedAtByGrowSpace ?? this.receivedAtByGrowSpace,
      lastFetchFailedByGrowSpace:
          lastFetchFailedByGrowSpace ?? this.lastFetchFailedByGrowSpace,
      activeBaseUrl:
          clearActiveBaseUrl ? null : (activeBaseUrl ?? this.activeBaseUrl),
      failureReason:
          clearFailureReason ? null : (failureReason ?? this.failureReason),
      lastFetchFailed: lastFetchFailed ?? this.lastFetchFailed,
      liveWarnThresholdMinutes:
          liveWarnThresholdMinutes ?? this.liveWarnThresholdMinutes,
      liveStaleThresholdMinutes:
          liveStaleThresholdMinutes ?? this.liveStaleThresholdMinutes,
    );
  }

  DateTime? get lastUpdatedAt {
    DateTime? latest;
    for (final t in receivedAtByGrowSpace.values) {
      if (latest == null || t.isAfter(latest)) latest = t;
    }
    return latest;
  }

  bool get isConnected =>
      status == HALiveConnectionStatus.live ||
      status == HALiveConnectionStatus.degradedRest;

  HALiveFreshness resolveFreshness({
    required String growSpaceId,
    DateTime? now,
  }) {
    final timestamp = receivedAtByGrowSpace[growSpaceId];
    final usable = readingsByGrowSpace[growSpaceId]?.hasUsableValues ?? false;
    final failed = lastFetchFailedByGrowSpace[growSpaceId] ?? lastFetchFailed;
    final age = timestamp == null
        ? null
        : (now ?? DateTime.now()).difference(timestamp);
    final status = !isConnected || timestamp == null
        ? HALiveFreshnessStatus.offline
        : age! >= Duration(minutes: liveStaleThresholdMinutes)
            ? HALiveFreshnessStatus.stale
            : age >= Duration(minutes: liveWarnThresholdMinutes)
                ? HALiveFreshnessStatus.warning
                : HALiveFreshnessStatus.healthy;
    return HALiveFreshness(
      status: status,
      lastUpdatedAt: timestamp,
      age: age,
      hasUsableValues: usable,
      lastAttemptFailed: failed,
    );
  }
}
