import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/core/database/database.dart';
import 'package:open_tomato/core/security/secure_storage.dart';
import 'package:open_tomato/features/home_assistant/data/models/ha_live_update_models.dart';
import 'package:open_tomato/features/home_assistant/data/repositories/grow_spaces_repository.dart';
import 'package:open_tomato/features/home_assistant/data/repositories/ha_settings_repository.dart';
import 'package:open_tomato/features/home_assistant/data/services/ha_environment_sync_service.dart';
import 'package:open_tomato/features/home_assistant/data/services/ha_history_backfill_service.dart';
import 'package:open_tomato/features/home_assistant/data/services/ha_history_service.dart';
import 'package:open_tomato/features/home_assistant/domain/exceptions/ha_exceptions.dart';

import 'fake_token_store.dart';

void main() {
  late AppDatabase db;
  late HaEnvironmentSyncService sync;
  late HASettingsRepository settings;
  late GrowSpacesRepository spaces;
  late FakeSecureStorage storage;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sync = HaEnvironmentSyncService(snapshots: db.environmentSnapshotsDao);
    storage = FakeSecureStorage();
    settings = HASettingsRepository(
      dao: db.haSettingsDao,
      tokenStore: HaAccessTokenStore(storage),
    );
    spaces = GrowSpacesRepository(db.growSpacesDao);
    await spaces.update(
      id: 'default',
      name: 'Greenhouse',
      tempEntityId: 'sensor.t',
      humidityEntityId: 'sensor.h',
    );
  });

  tearDown(() => db.close());

  test('syncReadings sanitises, recomputes VPD, keeps upstream as provenance',
      () async {
    final written = await sync.syncReadings(
      timestamp: DateTime(2026, 9, 1, 12),
      readingsByGrowSpace: {
        'default': const HALiveReading(
          tempF: 77,
          humidityPct: 60,
          vpdKpa: 9.9,
          soilMoisturePct: 40,
        ),
        'empty': const HALiveReading(
          tempF: -500,
          humidityPct: null,
          vpdKpa: null,
          soilMoisturePct: null,
        ),
      },
      source: HaEnvironmentSyncService.sourceLive,
    );
    expect(written, {'default'});
    final row =
        await db.environmentSnapshotsDao.getLatestForGrowSpace('default');
    expect(row!.vpdKpa, closeTo(1.27, 0.01));
    expect(row.upstreamVpdKpa, 9.9);
    expect(row.soilMoisturePct, 40);
    expect(row.source, 'ha_live');
  });

  test('upsert replaces the same timestamp instead of duplicating', () async {
    final at = DateTime(2026, 9, 1, 12);
    await sync.syncReadings(
      timestamp: at,
      readingsByGrowSpace: {
        'default': const HALiveReading(
          tempF: 70,
          humidityPct: 50,
          vpdKpa: null,
          soilMoisturePct: null,
        ),
      },
      source: 'ha_poll',
    );
    await sync.syncReadings(
      timestamp: at,
      readingsByGrowSpace: {
        'default': const HALiveReading(
          tempF: 71,
          humidityPct: 50,
          vpdKpa: null,
          soilMoisturePct: null,
        ),
      },
      source: 'ha_live',
    );
    final rows = await db.environmentSnapshotsDao
        .getWindow(growSpaceId: 'default', fromInclusive: at, toInclusive: at);
    expect(rows.single.tempF, 71);
    expect(rows.single.source, 'ha_live');
  });

  group('backfill', () {
    test('bucketize averages within five-minute buckets', () {
      final base = DateTime(2026, 9, 1, 12);
      final readings = HaHistoryBackfillService.bucketize({
        'temperature': [
          HaHistoryPoint(timestamp: base, value: 70),
          HaHistoryPoint(
            timestamp: base.add(const Duration(minutes: 2)),
            value: 72,
          ),
          HaHistoryPoint(
            timestamp: base.add(const Duration(minutes: 6)),
            value: 80,
          ),
        ],
        'humidity': [
          HaHistoryPoint(
            timestamp: base.add(const Duration(minutes: 1)),
            value: 55,
          ),
        ],
      });
      expect(readings.length, 2);
      expect(readings.first.tempF, 71);
      expect(readings.first.humidityPct, 55);
      expect(readings.last.tempF, 80);
      expect(readings.last.humidityPct, isNull);
    });

    test('runs only when configured, writes rows, and respects the throttle',
        () async {
      var now = DateTime(2026, 9, 1, 12);
      var calls = 0;
      final service = HaHistoryBackfillService(
        snapshots: db.environmentSnapshotsDao,
        settings: settings,
        growSpaces: spaces,
        sync: sync,
        now: () => now,
        seriesLoader: ({
          required entityId,
          required from,
          required to,
          required field,
        }) async {
          calls++;
          return [
            for (var i = 0; i < 12; i++)
              HaHistoryPoint(
                timestamp: from.add(Duration(minutes: 5 * i)),
                value: field == 'temperature' ? 72 : 60,
              ),
          ];
        },
      );
      expect(await service.runIfEligible(), 0, reason: 'not configured');
      await settings.saveSettings(
        baseUrl: 'http://ha.local',
        accessToken: 'tok',
        isEnabled: true,
        pollIntervalMinutes: 15,
        liveWarnThresholdMinutes: 5,
        liveStaleThresholdMinutes: 15,
      );
      final written = await service.runIfEligible();
      expect(written, 12);
      expect(calls, 2);
      final latest =
          await db.environmentSnapshotsDao.getLatestForGrowSpace('default');
      expect(latest!.source, 'ha_backfill');
      expect(latest.vpdKpa, isNotNull);

      expect(await service.runIfEligible(), 0, reason: 'throttled');
      now = now.add(const Duration(minutes: 20));
      expect(
        await service.runIfEligible(),
        12,
        reason: 'the gap since the last stored reading is refilled',
      );
    });

    test('a fresh mapping whose only row is a live reading fills the window',
        () async {
      await settings.saveSettings(
        baseUrl: 'http://ha.local',
        accessToken: 'tok',
        isEnabled: true,
        pollIntervalMinutes: 15,
        liveWarnThresholdMinutes: 5,
        liveStaleThresholdMinutes: 15,
      );
      final now = DateTime(2026, 9, 1, 12);
      // The live path wrote its first reading a minute ago, before this pass.
      await db.environmentSnapshotsDao.upsertSnapshot(
        growSpaceId: 'default',
        timestamp: now.subtract(const Duration(minutes: 1)),
        source: 'ha_live',
        tempF: 73,
        rhPct: 60,
        vpdKpa: 1.0,
        upstreamVpdKpa: null,
      );
      final froms = <DateTime>[];
      final service = HaHistoryBackfillService(
        snapshots: db.environmentSnapshotsDao,
        settings: settings,
        growSpaces: spaces,
        sync: sync,
        now: () => now,
        seriesLoader: ({
          required entityId,
          required from,
          required to,
          required field,
        }) async {
          froms.add(from);
          return [HaHistoryPoint(timestamp: from, value: 70)];
        },
      );
      expect(await service.runIfEligible(), 1);
      expect(
        froms,
        everyElement(now.subtract(HaHistoryBackfillService.maxLookback)),
        reason: 'the whole lookback window is fetched, not the minute gap',
      );
    });

    test('a wholesale-failed pass does not arm the throttle', () async {
      await settings.saveSettings(
        baseUrl: 'http://ha.local',
        accessToken: 'tok',
        isEnabled: true,
        pollIntervalMinutes: 15,
        liveWarnThresholdMinutes: 5,
        liveStaleThresholdMinutes: 15,
      );
      var fail = true;
      var calls = 0;
      final service = HaHistoryBackfillService(
        snapshots: db.environmentSnapshotsDao,
        settings: settings,
        growSpaces: spaces,
        sync: sync,
        now: () => DateTime(2026, 9, 1, 12),
        seriesLoader: ({
          required entityId,
          required from,
          required to,
          required field,
        }) async {
          calls++;
          if (fail) throw HAConnectionException();
          return [HaHistoryPoint(timestamp: from, value: 70)];
        },
      );
      expect(await service.runIfEligible(), 0);
      fail = false;
      expect(await service.runIfEligible(), 1, reason: 'retried immediately');
      expect(calls, 4);
    });
  });

  test('settings save keeps the token out of the database', () async {
    await settings.saveSettings(
      baseUrl: 'http://ha.local/',
      accessToken: 'secret-token',
      isEnabled: true,
      pollIntervalMinutes: 3,
      liveWarnThresholdMinutes: 10,
      liveStaleThresholdMinutes: 5,
    );
    final row = await settings.getSettings();
    expect(row!.baseUrl, 'http://ha.local');
    expect(row.pollIntervalMinutes, 10);
    expect(row.liveStaleThresholdMinutes, 11);
    expect(row.toString(), isNot(contains('secret-token')));
    expect(await settings.getAccessToken(), 'secret-token');
    await settings.saveSettings(
      baseUrl: 'http://ha.local',
      accessToken: '',
      isEnabled: false,
      pollIntervalMinutes: 15,
      liveWarnThresholdMinutes: 5,
      liveStaleThresholdMinutes: 15,
    );
    expect(
      await settings.getAccessToken(),
      'secret-token',
      reason: 'empty token keeps the stored one',
    );
  });
}
