import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/features/home_assistant/data/models/ha_entity_state.dart';
import 'package:open_tomato/features/home_assistant/data/services/ha_reading_normalizer.dart';

HAEntityState _state(String value, {String? unit}) => HAEntityState(
      entityId: 'sensor.x',
      state: value,
      attributes: {if (unit != null) 'unit_of_measurement': unit},
      lastChanged: DateTime(2026, 9, 1),
    );

void main() {
  const n = HAReadingNormalizer();

  test('temperature converts °C and rejects implausible values', () {
    expect(n.temperatureF(_state('25', unit: '°C')), closeTo(77, 0.01));
    expect(n.temperatureF(_state('75.4', unit: '°F')), closeTo(75.4, 0.01));
    expect(n.temperatureF(_state('75.4')), closeTo(75.4, 0.01));
    expect(n.temperatureF(_state('-557', unit: '°F')), isNull);
    expect(n.temperatureF(_state('unavailable')), isNull);
  });

  test('VPD in psi or without a unit is converted to kPa', () {
    expect(n.vpdKpa(_state('0.15', unit: 'psi')), closeTo(1.034, 0.01));
    expect(n.vpdKpa(_state('0.15')), closeTo(1.034, 0.01));
    expect(n.vpdKpa(_state('1.1', unit: 'kPa')), closeTo(1.1, 0.001));
    expect(n.vpdKpa(_state('11', unit: 'hPa')), closeTo(1.1, 0.001));
    expect(n.vpdKpa(_state('99', unit: 'kPa')), isNull);
  });

  test('canonical VPD prefers the recomputed value', () {
    final canonical =
        n.canonicalVpd(tempF: 77, humidityPct: 60, upstreamVpdKpa: 9);
    expect(canonical, closeTo(1.27, 0.01));
    expect(
      n.canonicalVpd(tempF: null, humidityPct: 60, upstreamVpdKpa: 1.3),
      1.3,
    );
  });

  test('humidity and soil moisture are clamped to a percent range', () {
    expect(n.humidityPct(_state('62.5')), 62.5);
    expect(n.humidityPct(_state('-327.7')), isNull);
    expect(n.soilMoisturePct(_state('140')), isNull);
  });
}
