import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/core/database/database.dart';
import 'package:open_tomato/features/home_assistant/data/models/ha_entity_state.dart';
import 'package:open_tomato/features/home_assistant/data/models/ha_live_update_models.dart';
import 'package:open_tomato/features/home_assistant/data/repositories/grow_spaces_repository.dart';
import 'package:open_tomato/features/home_assistant/data/services/ha_entity_state_parser.dart';
import 'package:open_tomato/features/home_assistant/data/services/ha_live_routing.dart';

HAEntityState _state(String id, String value, {String? unit}) => HAEntityState(
      entityId: id,
      state: value,
      attributes: {if (unit != null) 'unit_of_measurement': unit},
      lastChanged: DateTime(2026, 9, 1),
    );

void main() {
  late AppDatabase db;
  late GrowSpacesRepository spaces;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    spaces = GrowSpacesRepository(db.growSpacesDao);
    await spaces.update(
      id: 'default',
      name: 'Greenhouse',
      tempEntityId: 'sensor.t',
      humidityEntityId: 'sensor.h',
      vpdEntityId: 'sensor.vpd',
    );
    final shelf = await spaces.create(
      name: 'Shelf',
      tempEntityId: 'sensor.t',
      humidityEntityId: 'sensor.h2',
    );
    await spaces.setEnabled(shelf, false);
  });

  tearDown(() => db.close());

  test('routing follows enabled grow spaces and shares entities', () async {
    final routing = HALiveRouting();
    await routing.rebuild(spaces);
    expect(routing.entityIds.toSet(), {'sensor.t', 'sensor.h', 'sensor.vpd'});
    expect(routing.growSpaceIds, {'default'});

    expect(
      routing.apply('sensor.t', _state('sensor.t', '25', unit: '°C')),
      {'default'},
    );
    expect(routing.readingFor('default').tempF, closeTo(77, 0.01));
    expect(routing.readingFor('default').hasAirValues, isTrue);
    routing.apply('sensor.h', _state('sensor.h', '60', unit: '%'));
    routing.apply('sensor.vpd', _state('sensor.vpd', '0.05', unit: 'psi'));
    final reading = routing.readingFor('default');
    expect(
      reading.vpdKpa,
      closeTo(1.27, 0.01),
      reason: 'recomputed, not the psi entity',
    );
    expect(
      routing.apply('sensor.unknown', _state('sensor.unknown', '1')),
      isEmpty,
    );
  });

  test('hasUsableStates does not mutate the live routing', () async {
    final routing = HALiveRouting();
    await routing.rebuild(spaces);
    expect(
      routing.hasUsableStates({'sensor.h': _state('sensor.h', '55')}),
      isTrue,
    );
    expect(routing.readingFor('default').hasUsableValues, isFalse);
    expect(
      routing.hasUsableStates({'sensor.h': _state('sensor.h', 'unavailable')}),
      isFalse,
    );
  });

  test('state parser accepts only state_changed events with a new state', () {
    const parser = HAEntityStateParser();
    expect(parser.parseStateChangedEvent({'type': 'result'}), isNull);
    final parsed = parser.parseStateChangedEvent({
      'type': 'event',
      'event': {
        'event_type': 'state_changed',
        'data': {
          'entity_id': 'sensor.t',
          'new_state': {
            'entity_id': 'sensor.t',
            'state': '70',
            'attributes': {},
            'last_changed': '2026-09-01T10:00:00Z',
          },
        },
      },
    });
    expect(parsed!.entityId, 'sensor.t');
    expect(parsed.nextState.numericState, 70);
  });

  test('freshness is derived from receive time and thresholds', () {
    final now = DateTime(2026, 9, 1, 12);
    final snap = HALiveTelemetrySnapshot.initial().copyWith(
      status: HALiveConnectionStatus.live,
      receivedAtByGrowSpace: {
        'default': now.subtract(const Duration(minutes: 7)),
      },
      readingsByGrowSpace: {
        'default': const HALiveReading(
          tempF: 70,
          humidityPct: 50,
          vpdKpa: 1,
          soilMoisturePct: null,
        ),
      },
    );
    expect(
      snap.resolveFreshness(growSpaceId: 'default', now: now).status,
      HALiveFreshnessStatus.warning,
    );
    expect(
      snap
          .resolveFreshness(
            growSpaceId: 'default',
            now: now.add(const Duration(minutes: 10)),
          )
          .status,
      HALiveFreshnessStatus.stale,
    );
    expect(
      snap.resolveFreshness(growSpaceId: 'other', now: now).status,
      HALiveFreshnessStatus.offline,
    );
    expect(
      snap
          .copyWith(status: HALiveConnectionStatus.offline)
          .resolveFreshness(growSpaceId: 'default', now: now)
          .isOffline,
      isTrue,
    );
  });
}
